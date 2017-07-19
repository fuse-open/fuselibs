using Uno;
using Uno.UX;

using Fuse.Controls;
using Fuse.Triggers.Actions;

namespace Fuse.Gestures
{
	public enum ScrollToHow
	{
		Goto,
		Seek,
	}
	
	/** Scrolls a @ScrollView to a given position when triggered.
	
		### Absolute position
	
		To scroll to an absolute position, provide a value to the `Position` property.
		This property accepts a pair of numbers, representing X and Y coordinates.
			
			<ScrollTo Target="myScrollView" Position="0, 50" />
		
		### Relative position
		
		Alternatively, you can scroll to a relative position using the `RelativePosition` property.
		
		`RelativePosition` also accepts a pair of numbers, representing X and Y coordinates.
		Each coordinate should be in the range `0..1`, where `1` represents the largest distance
		the user can scroll in that direction.
		For instance, a `RelativePosition` of `1, 1` will scroll to the bottom-right corner.
		
			<ScrollTo Target="myScrollView" RelativePosition="0, 0.5" />
			
		When triggered, the above will scroll `myScrollView` to the vertical center of its scrollable area.
		
		## Example
		
			<DockPanel>
				<Button Dock="Top" Text="Scroll to top" Margin="20">
					<Clicked>
						<ScrollTo Target="myScrollView" Position="0,0" />
					</Clicked>
				</Button>
			
				<ScrollView ux:Name="myScrollView">
					<Rectangle Height="2000">
						<LinearGradient>
							<GradientStop Offset="0" Color="Red" />
							<GradientStop Offset="1" Color="Blue" />
						</LinearGradient>
					</Rectangle>
				</ScrollView>
			</DockPanel>
	*/
	public class ScrollTo : TriggerAction
	{
		/** The @ScrollView to perform the scrolling on. */
		public ScrollView Target { get; set; }
		
		float2 _position;
		bool _hasPosition;
		/** The absolute position to scroll to, in points. */
		public float2 Position
		{
			get { return _position; }
			set
			{
				_position = value;
				_hasPosition = true;
			}
		}
		
		float2 _relativePosition;
		bool _hasRelativePosition;
		/** The position to scroll to, relative to the size of the scrollable area.
		
			Each coordinate should be in the range `0..1`, where `1` represents the largest distance
			the user can scroll in that direction.
			For instance, a `RelativePosition` of `1, 1` will scroll to the bottom-right corner.
			
			If specified, this takes precedence over `Position`.
		*/
		public float2 RelativePosition
		{
			get { return _relativePosition; }
			set
			{
				_relativePosition = value;
				_hasRelativePosition = true;
			}
		}
	
		ScrollToHow _how = ScrollToHow.Goto;
		public ScrollToHow How
		{
			get { return _how; }
			set { _how = value; }
		}
		
		protected override void Perform(Node target)
		{
			var scrollView = Target ?? target.FindByType<ScrollView>();
			if (scrollView == null)
			{
				Fuse.Diagnostics.UserError( "Unabled to locate ScrollView", this );
				return;
			}
				
			var toPos = _hasRelativePosition ?
				scrollView.RelativeToAbsolutePosition(_relativePosition) :
				_position;
				
			if (How == ScrollToHow.Goto)
				scrollView.Goto(toPos);
			else
				scrollView.ScrollPosition = toPos;
		}
	}

	/**
		Scrolls a @ScrollView to a given position when triggered.

		Note that this action is deprecated, you should now use @ScrollTo instead.
	*/
	public class ScrollableGoto : ScrollTo
	{
		//DEPRECATED: 2016-03-31
		public ScrollableGoto()
		{
			Fuse.Diagnostics.Deprecated( "Use ScrollTo instead, it has the same interface", this );
		}
	}
}