using Uno;
using Fuse.Platform;

namespace Fuse.Triggers.Actions
{
	/**
		Change Screen Orientation

		## Example

			<Page>
				<Activated>
					<SetWindowOrientation To="LandscapeLeft" />
				</Activated>
			</Page>
	*/
	public class SetWindowOrientation : TriggerAction
	{
		/* Target Orientation */
		public ScreenOrientation To
		{
			get; set;
		}

		protected override void Perform(Node n)
		{
			SystemUI.DeviceOrientation = To;
		}
	}
}
