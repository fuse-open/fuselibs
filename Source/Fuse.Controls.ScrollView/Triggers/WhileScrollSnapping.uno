using Uno;
using Uno.UX;

using Fuse.Elements;
using Fuse.Controls;

namespace Fuse.Triggers
{
	/**
		Active while an element is positioned within the snapping area.
		```xml
			<ScrollView LayoutMode="PreserveVisual">
				<StackPanel>
					<Each Count="100" Reuse="Frame" >
						<Panel ux:Name="panel" Color="#AAA">
							<Text ux:Name="text" Value="Data-{= index() }"/>

							<WhileScrollSnapping>
								<Change panel.Color="Blue" />
								<Change text.Color="White" />
							</WhileScrollSnapping>
						</Panel>
					</Each>
				</StackPanel>

				<ScrollViewSnap SnapAlignment="Center" />
			</ScrollView>
		```

		@experimental
	*/
	public class WhileScrollSnapping : WhileTrigger, IPropertyListener
	{
		ScrollView _scrollable;
		ScrollViewSnap _scrollViewSnap;
		protected override void OnRooted()
		{
			base.OnRooted();
			_scrollable = Parent.FindByType<ScrollView>();
			if (_scrollable == null)
			{
				Fuse.Diagnostics.UserError( "Could not find a ScrollView control.", this );
				return;
			}

			_scrollable.AddPropertyListener(this);
			_scrollViewSnap = _scrollable.FirstChild<ScrollViewSnap>();

			if (_scrollViewSnap == null)
			{
				Fuse.Diagnostics.UserError( "Could not find a ScrollViewSnap Behavior.", this );
				return;
			}
		}

		protected override void OnUnrooted()
		{
			if (_scrollable != null)
			{
				_scrollable.RemovePropertyListener(this);
				_scrollable = null;
				_scrollViewSnap = null;
			}
			base.OnUnrooted();
		}

		void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector prop)
		{
			SetActive(IsOn);
		}


		float ToScalarPosition( float2 value )
		{
			if (_scrollable.AllowedScrollDirections == ScrollDirections.Horizontal)
				return value.X;
			else if (_scrollable.AllowedScrollDirections == ScrollDirections.Vertical)
				return value.Y;
			return (value.X + value.Y) /2;
		}

		bool IsOn
		{
			get
			{
				if (_scrollable != null && _scrollViewSnap != null)
				{
					var snapAlign = _scrollViewSnap.SnapAlignment;
					var element = Parent as Element;
					var scrollPos = ToScalarPosition(_scrollable.ScrollPosition);
					switch (snapAlign)
					{
						case SnapAlign.Start:
							var from = ToScalarPosition(element.ActualPosition - _scrollViewSnap.GetChildSize * Within);
							var to = ToScalarPosition(element.ActualPosition + _scrollViewSnap.GetChildSize);
							return from <= scrollPos && to >= scrollPos;
						case SnapAlign.End:
							var from = ToScalarPosition(element.ActualPosition - _scrollViewSnap.CalculateOffset() - _scrollViewSnap.GetChildSize);
							var to = ToScalarPosition(element.ActualPosition - _scrollViewSnap.CalculateOffset() + _scrollViewSnap.GetChildSize * Within);
							return from <= scrollPos && to >= scrollPos;
						case SnapAlign.Center:
							var from = ToScalarPosition(element.ActualPosition - _scrollViewSnap.CalculateOffset() - _scrollViewSnap.GetChildSize * Within);
							var to = ToScalarPosition(element.ActualPosition - _scrollViewSnap.CalculateOffset() + _scrollViewSnap.GetChildSize * Within);
							return from <= scrollPos && to >= scrollPos;
					}
				}
				return false;
			}
		}

		float _within = 0.5f;
		public float Within
		{
			get { return _within; }
			set
			{
				_within = Math.Clamp(value, 0, 1);
				SetActive(IsOn);
			}
		}
	}
}