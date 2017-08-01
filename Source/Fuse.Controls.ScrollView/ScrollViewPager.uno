using Uno;
using Uno.UX;

using Fuse.Reactive;

namespace Fuse.Controls
{
	public class ScrollViewPagerArgs : EventArgs
	{
	}

	/**
		Paging and loading manager for a list of items. Allows a large, or infinite list, to be displayed in a `ScrollView`.
		
		This controls the `Each.Offset` and `Each.Limit` values while using `Each` within a `ScrollView`. It limits the number of items actually displayed to improve performance.
		
		The setup that works now is with a `StackPanel` (Horizontal or Vertical)
		
			<ScrollView LayoutMode="PreserveVisual">
				<StackPanel>
					<Each Items="{items}" Reuse="Frame" ux:Name="theEach">
						<Panel Color="#AAA">
							<Text Value="{title}"/>
						</Panel>
					</Each>
				</StackPanel>
				
				<ScrollViewPager Each="theEach" ReachedEnd="{loadMore}"/>
			</ScrollView>
			
		It's required that `LayoutMode="PreserveVisual"` is used, otherwise the scrolling will not function correctly. `Reuse="Frame"` is optional but recommended: it improves performance be reusing objects.
		
		`ReachedEnd` is called when the true end of the list is reached and more data is required. It's actually called somewhat before the end is reached, starting any loading before the user reaches the end. There is also a `RechedStart` to allow loading when scrolling the opposite direction.  Neither of these callbacks are mandatory; `ScrollViewPager` is also helpful for displaying large static lists.
		
		@experimental
	*/
	public partial class ScrollViewPager : Behavior, IPropertyListener
	{
		int _retain = 3;
		/**
			An approximate number of pages to retain. The size of the visible part of the `ScrollView` is the page size. Enough items to fill multiple amounts of this size are kept around. The rest are discarded.
			
			The default of `3` is about as low as you can go to not interrupt common scrolling. If you have small scrollable list, or expect the user to fling often, you may increase this value.
		*/
		public int Retain
		{
			get { return _retain; }
			set
			{
				if (_retain == value)
					return;
					
				_retain = value;
			}
		}

		/**
			When scrolled to this number of pages from the end the `ReachedStart` or `ReachedEnd` event will be raised.
		*/
		float _endRange = 0.75f;
		public float EndRange
		{
			get { return _endRange; }
			set
			{
				if (_endRange == value)
					return;
				
				_endRange = value;
			}
		}
		
		Each _each;
		/**
			The `Each` instance to control. This parameter is required.
		*/
		public Each Each 
		{
			get { return _each; }
			set { _each = value; }
		}
		
		ScrollViewBase _scrollable;
		protected override void OnRooted()
		{
			base.OnRooted();

			if (Each == null)
			{
				Fuse.Diagnostics.UserError( "Require an Each", this );
				return;
			}
			
			if (!Each.HasLimit)
				Each.Limit = 1;
			
			_scrollable = Parent.FindByType<ScrollViewBase>();
			if (_scrollable == null)
			{
				Fuse.Diagnostics.UserError( "Could not find a Scrollable control.", this );
				return;
			}
			
			_scrollable.AddPropertyListener(this);
			_prevActualSize = float2(0);
		}
		
		protected override void OnUnrooted()
		{
			if (_scrollable != null)
			{
				_scrollable.RemovePropertyListener(this);
				_scrollable = null;
			}
			
			base.OnUnrooted();
		}
		
		void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector prop)
		{
			if (obj != _scrollable)
				return;
				
			if (prop == ScrollView.ScrollPositionName)
			{
				if (!_pendingPosition)
				{
					UpdateManager.AddDeferredAction(CheckPosition);
					_pendingPosition = true;
				}
			}
			else if (prop == ScrollView.SizingChanged)
			{
				if (!_pendingSizing)
				{
					UpdateManager.AddDeferredAction(CheckSizing);
					_pendingSizing = true;
				}
			}
		}
		
		bool _pendingPosition;
		bool _pendingSizing;

		public delegate void ScrollViewPagerHandler(object s, ScrollViewPagerArgs args);
		
		/**
			Raised when the `ScrollView` comes near the end of the data.
		*/
		public event ScrollViewPagerHandler ReachedEnd;
		
		/**
			Raised when the `ScrollView` comes near the start of the data.
		*/
		public event ScrollViewPagerHandler ReachedStart;
		
		bool _nearTrueEnd;
		bool _nearTrueStart;
		void CheckPosition()
		{
			_pendingPosition = false;
			var nearEnd = _scrollable.ToScalarPosition( (_scrollable.MaxScroll - _scrollable.ScrollPosition) /
				_scrollable.ActualSize) < EndRange;
			var nearStart = _scrollable.ToScalarPosition( (_scrollable.ScrollPosition - _scrollable.MinScroll) /
				_scrollable.ActualSize) < EndRange;
			
			var nearTrueEnd = false;
			var nearTrueStart = false;
			
			if (nearEnd && nearStart)
			{
				//nothing, otherwise we'd flip back and forth
				nearTrueEnd = true;
				nearTrueStart = true;
			}
			else if (nearEnd)
			{
				var offset = Each.Offset;
				var limit = Each.Limit;
				var count = Each.DataCount;
				
				if (offset + limit < count)
					Each.Offset = offset + 1;
				else
					nearTrueEnd = true;
			}
			else if (nearStart)
			{
				var offset = Each.Offset;
				if (offset > 0)
					Each.Offset = offset - 1;
				else
					nearTrueStart = true;
			}
			
			if (nearTrueStart != _nearTrueStart && nearTrueStart)
			{	
				if (ReachedStart != null)
					ReachedStart(this, new ScrollViewPagerArgs());
			}
			_nearTrueStart = nearTrueStart;
			
			if (nearTrueEnd != _nearTrueEnd &&  nearTrueEnd)
			{
				if (ReachedEnd != null)
					ReachedEnd(this, new ScrollViewPagerArgs());
			}
			_nearTrueEnd = nearTrueEnd;
		}

		float2 _prevActualSize;
		void CheckSizing()
		{
			_pendingSizing = false;
			var range = _scrollable.MaxScroll - _scrollable.MinScroll;
			var pages = _scrollable.ContentMarginSize / _scrollable.ActualSize;

			var scalarPages = _scrollable.ToScalarPosition(pages);
			if (scalarPages < Retain)
			{
				var count = Each.DataCount;
				var offset = Each.Offset;
				var limit = Each.Limit;
				
				if (offset + limit < count)
					Each.Limit = limit + 1;
			}
			else if (scalarPages > Retain &&
				_scrollable.ToScalarPosition(_scrollable.ActualSize) < _scrollable.ToScalarPosition(_prevActualSize) )
			{
				//only reduce when the ScrollView itself is being shrunk in size, otherwise we run the risk
				//of flickering between to sizes for an element that pushes it back/forth over the limit
				var limit = Each.Limit;
				
				if (limit > 1)
					Each.Limit = limit - 1;
			}
		}
		
	}
}
