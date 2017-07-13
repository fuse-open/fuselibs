using Uno;
using Fuse;
using Fuse.Elements;
using Fuse.Controls;

namespace Fuse.Triggers.Actions
{
	/** Reorders the siblings of a @Visual so that the @Visual will be rendered on top.

		> Note that it doesn't affect the @Visual's `ZOffset`. Instead, it reorders the @Visual amongst its siblings so that it will be drawn on top.
		> This means that using `ZOffset` can still cause this @Visual to be rendered underneath its siblings.

		## Example

			<ScrollView>
				<Grid Rows="400, 1*" Margin="10">
					<Panel>
						<Rectangle Margin="10" CornerRadius="4" ux:Name="topRect">
							<LinearGradient>
								<GradientStop Offset="0" Color="#a542db" />
								<GradientStop Offset="1" Color="#3579e6" />
							</LinearGradient>
						</Rectangle>
						<TextBlock ux:Name="textBehind" Alignment="Center" FontSize="20" Color="#fff">I was brought to the front!</TextBlock>
					</Panel>
					<Rectangle Margin="10">
						<Stroke Offset="4" Width="1" Color="#3579e6" />
						<Button Text="Bring element to front" Alignment="Bottom">
							<Clicked>
								<BringToFront Target="textBehind" />
							</Clicked>
						</Button>
					</Rectangle>
				</Grid>
			</ScrollView>
	*/
	public class BringToFront : Fuse.Triggers.Actions.TriggerAction
	{
		public Visual Target { get; set; }

		protected override void Perform(Node target)
		{
			var elm = Target ?? target.FindByType<Visual>();
			if (elm != null)
			{
				var panel = elm.Parent as Visual;
				if (panel != null)
					panel.BringToFront(elm);
			}
		}
	}

	/** Reorders the siblings of a @Visual so that the @Visual will be rendered underneath.

		> Note that it doesn't affect the @Visual's `ZOffset`. Instead, it reorders the @Visual amongst its siblings so that it will be drawn underneath.
		> This means that using `ZOffset` can still cause this @Visual to be rendered on top of its siblings.

		## Example

			<ScrollView>
				<Grid Rows="400, 1*" Margin="10">
					<Panel>
						<TextBlock ux:Name="textInFront" Alignment="Center" FontSize="20" Color="#fff">I'll be sent to the back!</TextBlock>
						<Rectangle Margin="10" CornerRadius="4" ux:Name="topRect">
							<LinearGradient>
								<GradientStop Offset="0" Color="#a542db" />
								<GradientStop Offset="1" Color="#3579e6" />
							</LinearGradient>
						</Rectangle>
					</Panel>
					<Rectangle Margin="10">
						<Stroke Offset="4" Width="1" Color="#3579e6" />
						<Button Text="Send element to back" Alignment="Bottom">
							<Clicked>
								<SendToBack Target="textInFront" />
							</Clicked>
						</Button>
					</Rectangle>
				</Grid>
			</ScrollView>
	*/
	public class SendToBack : Fuse.Triggers.Actions.TriggerAction
	{
		public Visual Target { get; set; }

		protected override void Perform(Node target)
		{
			var elm = Target ?? target.FindByType<Visual>();
			if (elm != null)
			{
				var panel = elm.Parent as Visual;
				if (panel != null)
					panel.SendToBack(elm);
			}
		}
	}
}
