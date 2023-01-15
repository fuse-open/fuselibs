using Uno;
using Uno.UX;

using Fuse.Elements;
using Fuse.Controls;

namespace Fuse.Controls
{
	/**
		How the lock position of ScrollView viewport are treated.
	*/
	public enum SnapAlign
	{
		Start,
		Center,
		End
	}

	/**
		Add scroll snapping behavior to the `ScrollView`. Scroll snapping allows you to lock the viewport to certain location after a user has finished scrolling.

		You can use `SnapAlignment` property to control the lock position. There are three lock position available, `Start`, `Center` and `End`.

		The setup that works now is with a `StackPanel` (Horizontal or Vertical)
		```xml
			<ScrollView LayoutMode="PreserveVisual">
				<StackPanel>
					<Each Count="100" Reuse="Frame" >
						<Panel Color="#AAA">
							<Text Value="Data {= index() }"/>
						</Panel>
					</Each>
				</StackPanel>

				<ScrollViewSnap SnapAlignment="Center" />
			</ScrollView>
		```
		It's required to use `LayoutMode="PreserveVisual"` on the `ScrollView` and the child element in the `StackPanel` has an equal size.

		@experimental
	*/
	public partial class ScrollViewSnap : Behavior, IPropertyListener
	{
		SnapAlign _snapAlign = SnapAlign.Center;
		static Selector _snapAlignmentName = "SnapAlignment";
		/**
			The lock position of ScrollView viewport are treated
			@Default Center
		*/
		public SnapAlign SnapAlignment
		{
			get { return _snapAlign; }
			set
			{
				SetSnapAlignment(value, this);
			}
		}

		public void SetSnapAlignment(SnapAlign snapAlign, IPropertyListener origin)
		{
			if (snapAlign != _snapAlign)
			{
				_snapAlign = snapAlign;
				OnPropertyChanged(_snapAlignmentName, origin);
				CheckSizing();
			}
		}

		/**
			Raised whenever the scroll snap changes.
		*/
		public event VisualEventHandler SnapHandler;

		ScrollViewBase _scrollable;
		StackPanel _element;
		protected override void OnRooted()
		{
			base.OnRooted();
			_scrollable = Parent.FindByType<ScrollViewBase>();
			if (_scrollable == null)
			{
				Fuse.Diagnostics.UserError( "Could not find a ScrollView control.", this );
				return;
			}

			_element = _scrollable.Content as StackPanel;
			if (_element == null)
			{
				Fuse.Diagnostics.UserError( "Content of ScrollView is not an StackPanel", this );
				return;
			}

			//this mode won't work correctly, emit a warning with a suitable one
			if (_scrollable.LayoutMode == ScrollViewLayoutMode.PreserveScrollPosition)
			{
				Fuse.Diagnostics.UserError( "The ScrollView should have `LayoutMode=\"PreserveVisual\"` to work correctly", this );
				return;
			}

			_scrollable.AddPropertyListener(this);
			_scrollable.IsInteractingChanged += OnInteractingChanged;
		}

		protected override void OnUnrooted()
		{
			if (_scrollable != null)
			{
				_scrollable.RemovePropertyListener(this);
				_scrollable.IsInteractingChanged -= OnInteractingChanged;
				_selectedElement = null;
				_scrollable = null;
				_element = null;
			}
			base.OnUnrooted();
		}

		float2 _childSize = float2(0);
		internal float2 GetChildSize
		{
			get
			{
				if (_childSize.X == 0 && _childSize.Y == 0)
				{
					var element = _element.FirstChild<Element>();
					if (element != null)
						_childSize = element.ActualSize;
				}
				return _childSize;
			}
		}

		static Selector SizingChanged = "SizingChanged";
		static Selector ScrollPositionName = "ScrollPosition";

		void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector prop)
		{
			if (obj != _scrollable)
				return;

			if (prop == ScrollPositionName)
			{
				RequestCheckPosition();
			}

			if (prop == SizingChanged)
			{
				RequestCheckSizing();
			}

		}

		bool _isInteracting;
		void OnInteractingChanged(object s, object a)
		{
			bool n = _scrollable.IsInteracting;
			if (n == _isInteracting)
				return;
			_isInteracting = n;
			Timer.Wait(0.05, SelectItem);
		}

		bool _pendingSizing;
		void RequestCheckSizing()
		{
			if (!_pendingSizing)
			{
				UpdateManager.AddDeferredAction(CheckSizing);
				_pendingSizing = true;
			}
		}

		float2 NormalizeOffset(float2 offset)
		{
			var p = offset;
			if (_scrollable.AllowedScrollDirections == ScrollDirections.Vertical)
				p.X = 0;
			else if (_scrollable.AllowedScrollDirections == ScrollDirections.Horizontal)
				p.Y = 0;
			return p;
		}

		internal float2 CalculateOffset()
		{
			var offset = float2(0);
			switch (SnapAlignment)
			{
				case SnapAlign.Center:
					offset = Math.Floor((_scrollable.ActualSize / 2 - GetChildSize / 2) + 0.5f);
					break;
				case SnapAlign.Start:
					offset = Math.Floor((_scrollable.ActualSize - GetChildSize) + 0.5f);
					break;
				case SnapAlign.End:
					offset = Math.Floor((_scrollable.ActualSize - GetChildSize) + 0.5f);
					break;
			}
			return NormalizeOffset(offset);
		}

		void CheckSizing()
		{
			if (_scrollable == null)
				return;

			var offset = CalculateOffset();
			switch (SnapAlignment)
			{
				case SnapAlign.Center:
					_element.Padding = float4(offset, offset);
					break;
				case SnapAlign.End:
					_element.Padding = float4(offset, 0, 0);
					break;
				case SnapAlign.Start:
					_element.Padding = float4(0, 0, offset);
					break;
			}
			_pendingSizing = false;
		}

		float2 _prevPos = float2(0);
		bool _scrollIsUp;
		void FindScrollDicrection()
		{
			_scrollIsUp = !(_scrollable.ScrollPosition.Y > _prevPos.Y);
			_prevPos = _scrollable.ScrollPosition;
		}

		bool _isScrolling;
		bool _pendingPosition;
		void RequestCheckPosition()
		{
			FindScrollDicrection();
			if (!_pendingSizing && !_pendingPosition)
			{
				_isScrolling = true;
				_pendingPosition = true;
				Timer.Wait(0.5, CheckScrolling);
			}
		}

		void CheckScrolling()
		{
			_pendingPosition = false;
			_isScrolling = false;
			Timer.Wait(0.1, SelectItem);
		}

		Element _selectedElement;
		int _selectedIndex = -1;

		void SelectItem()
		{
			if (_scrollable == null || _isScrolling || _isInteracting)
				return;

			_selectedIndex = FindIndex();
			_selectedElement = FindSelectedElement(_selectedIndex);
			if (_selectedElement == null)
				return;

			switch (SnapAlignment)
			{
				case SnapAlign.Center:
					_selectedElement.BringIntoView();
					break;
				case SnapAlign.End:
					var offset = float2(_element.Padding.X, _element.Padding.Y);
					_scrollable.Goto(_selectedElement.ActualPosition - offset);
					break;
				case SnapAlign.Start:
					_scrollable.Goto(_selectedElement.ActualPosition);
					break;
			}
			UpdateManager.AddDeferredAction(NotifyHandler);
			_scrollIsUp = false;
		}

		bool _pendingNotify;
		void NotifyHandler()
		{
			if (SnapHandler != null && _selectedElement != null && !_pendingNotify)
			{
				Snappable snappable;
				if (!TryFindSnappable(_selectedElement, out snappable))
				{
					snappable = new Snappable(SnapHandler);
					_selectedElement.Children.Add(snappable);
				}
				snappable.Perform();
				_pendingNotify = true;
				Timer.Wait(1, ResetNotify);
			}
		}

		void ResetNotify()
		{
			_pendingNotify = false;
		}

		int FindIndex()
		{
			var scrollPos = _scrollable.ScrollPosition;
			float2 snapPosition;
			if (!_scrollIsUp)
				snapPosition = Math.Floor((scrollPos / (GetChildSize + _element.ItemSpacing))+ 0.7f);
			else
				snapPosition = Math.Floor((scrollPos / (GetChildSize + _element.ItemSpacing)) + 0.5f);

			int index = -1;
			if (_scrollable.AllowedScrollDirections == ScrollDirections.Vertical)
				index = (int)snapPosition.Y;
			else if (_scrollable.AllowedScrollDirections == ScrollDirections.Horizontal)
				index = (int)snapPosition.X;

			return index;
		}

		Element FindSelectedElement(int index)
		{
			if (index == -1)
				return null;

			Element ele = null;
			int i = 0;
			for (var n = _element.FirstChild<Element>(); n != null; n = n.NextSibling<Element>())
			{
				if (index == i)
				{
					ele = n;
					break;
				}
				i++;
			}
			return ele;
		}

		bool TryFindSnappable( Node n, out Snappable snappable)
		{
			snappable = null;
			while (n != null)
			{
				var vs = n as Visual;
				if (vs != null)
				{
					if (snappable == null)
					{
						snappable = vs.FirstChild<Snappable>();
						if (snappable != null)
							return true;
					}
				}

				n = n.ContextParent;
			}
			snappable = null;
			return false;
		}

	}

	class Snappable : Behavior
	{

		public event VisualEventHandler SnapHandler;

		public Snappable(VisualEventHandler snapHandler)
		{
			SnapHandler = snapHandler;
		}

		public void Perform()
		{
			SnapHandler(this, new VisualEventArgs(Parent));
		}
	}


}
