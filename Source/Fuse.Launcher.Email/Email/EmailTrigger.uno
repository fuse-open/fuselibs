using Uno.UX;

namespace Fuse.Triggers.Actions
{
	/** Launch the default email application with an optional template

		You'll find this trigger action in the Fuse.Launcher package, which have to be referenced from your uno project.
		For example:

			{
				"Packages": [
					"Fuse",
					"FuseJS",
					"Fuse.Launcher"
				]
			}

		> Note it's expected that the 'To' parameter is set

		## Example

			<StackPanel Margin="20">
				<Button Margin="10" Text="Send email">
					<Clicked>
						<LaunchEmail To="email@example.com" Subject="Test" CarbonCopy="" BlindCarbonCopy="" Message="Hello world!" />
					</Clicked>
				</Button>
			</StackPanel>
	*/
	public class LaunchEmail : TriggerAction
	{
		public string To {get; set;}
		public string CarbonCopy {get; set;}
		public string BlindCarbonCopy {get; set;}
		public string Subject {get; set;}
		public string Message {get; set;}

		protected override void Perform(Node target)
		{
			Fuse.LauncherImpl.EmailLauncher.LaunchEmail(To, CarbonCopy, BlindCarbonCopy, Subject, Message);
		}
	}
}
