using Uno.UX;
using Fuse.Triggers.Actions;

namespace Fuse.Vibration
{
	/** Vibrate the device for a duration
	
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
	*/
	public class Vibrate : TriggerAction
	{
		public double Duration { get; set;}
	        
		protected override void Perform(Node target)
		{
			Vibration.Vibrate(Duration);
		}
	}
}
