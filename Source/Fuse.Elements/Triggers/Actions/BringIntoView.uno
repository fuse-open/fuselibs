using Uno;

using Fuse.Elements;

namespace Fuse.Triggers.Actions
{
	/** Scrolls a @fuse/controls/scrollview so that the target element becomes visible
		
		## Example

				<ScrollView>
					<Grid Rows="auto, 400, 400, 400, auto" Margin="10">
						<Button Text="Go to Bottom" Alignment="Bottom">
							<Clicked>
								<BringIntoView TargetNode="bottomRect" />
							</Clicked>
						</Button>
						<Rectangle Margin="10" CornerRadius="4" ux:Name="topRect">
							<SolidColor Color="#a542db" />
						</Rectangle>
						<Rectangle Margin="10" CornerRadius="4">
							<LinearGradient>
								<GradientStop Offset="0" Color="#a542db" />
								<GradientStop Offset="1" Color="#3579e6" />
							</LinearGradient>
						</Rectangle>
						<Rectangle Margin="10" CornerRadius="4" ux:Name="bottomRect">
							<Stroke Offset="4" Width="1" Color="#3579e6" />
							<SolidColor Color="#3579e6" />
						</Rectangle>
						<Button Text="Go to Top" Alignment="Bottom">
							<Clicked>
								<BringIntoView TargetNode="topRect" />
							</Clicked>
						</Button>
					</Grid>
				</ScrollView>
	*/
	public class BringIntoView : TriggerAction
	{
		protected override void Perform(Node target)
		{
			//use Visual for future-proofing this logic (it could be brought into view, just not supported now)
			var elm = target.FindByType<Visual>() as Element;
			if (elm != null)	
				elm.BringIntoView();
		}
	}
}