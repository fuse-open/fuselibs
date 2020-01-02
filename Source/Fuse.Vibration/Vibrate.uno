using Uno.UX;
using Fuse.Triggers.Actions;

namespace Fuse.Vibration
{
	/** Vibrate the device for a duration or by vibration type (only on iOS)

		You'll find this trigger action in the Fuse.Vibration package, which have to be referenced from your uno project.
		For example:

			{
				"Packages": [
					"Fuse",
					"FuseJS",
					"Fuse.Vibration"
				]
		  	}

		## Example

			<StackPanel Margin="20">
				<Button Margin="10" Text="Vibrate">
					<Clicked>
						<Vibrate Duration="5" />
					</Clicked>
				</Button>
			</StackPanel>

		On iOS you can do vibration by leveraging Taptic Engine. There are 9 types of vibration :
		* Soft
		* Rigid
		* Light
		* Medium
		* Heavy
		* Success
		* Warning
		* Error
		* Selection
		To activate it, just pass those value to `VibrationType` property

		##Example

			<StackPanel Margin="20">
				<!-- Works on iOS using Taptic Engine -->
				<Button Margin="10" Text="Heavy Vibrate">
					<Clicked>
						<Vibrate VibrationType="Heavy" />
					</Clicked>
				</Button>
			</StackPanel>
	*/
	public class Vibrate : TriggerAction
	{
		public double Duration { get; set;}

		VibrationType _vibrationType = VibrationType.Undefined;
		public VibrationType VibrationType
		{
			get
			{
				return _vibrationType;
			}
			set
			{
				_vibrationType = value;
			}
		}

		protected override void Perform(Node target)
		{
			if (_vibrationType != VibrationType.Undefined)
				Vibration.Feedback(_vibrationType);
			else
				Vibration.Vibrate(Duration);
		}
	}
}
