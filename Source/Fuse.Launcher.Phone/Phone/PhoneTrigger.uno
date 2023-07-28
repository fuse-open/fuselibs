namespace Fuse.Triggers.Actions
{
	/** Calls a phone number

		You'll find this trigger action in the Fuse.Launcher package, which have to be referenced from your uno project.
		For example:
		```json
			{
				"Packages": [
					"Fuse",
					"FuseJS",
					"Fuse.Launcher"
				]
			}
		```
		## Example
		```xml
			<StackPanel Margin="20">
				<TextInput PlaceholderText="Enter the number here" ux:Name="numberInput" />
				<Button Margin="10" Text="Call" Alignment="Bottom">
					<Clicked>
						<Call Number="{ReadProperty numberInput.Value}" />
					</Clicked>
				</Button>
			</StackPanel>
		```
	*/
	public class Call : TriggerAction
	{
		public string Number {get; set;}

		protected override void Perform(Node target)
		{
			Fuse.LauncherImpl.PhoneLauncher.LaunchCall(Number);
		}
	}

	/** Send a message to a phone number

		You'll find this trigger action in the Fuse.Launcher package, which have to be referenced from your uno project.
		For example:
		```json
			{
				"Packages": [
					"Fuse",
					"FuseJS",
					"Fuse.Launcher"
				]
			}
		```
		## Example
		```xml
			<StackPanel Margin="20">
				<TextInput PlaceholderText="Enter the number here" ux:Name="numberInput" />
				<Button Margin="10" Text="Call" Alignment="Bottom">
					<Clicked>
						<Sms Number="{ReadProperty numberInput.Value}" Body="Hi there" />
					</Clicked>
				</Button>
			</StackPanel>
		```
	*/
	public class Sms : TriggerAction
	{
		public string Number {get; set;}

		public string Body {get; set;}

		protected override void Perform(Node target)
		{
			Fuse.LauncherImpl.PhoneLauncher.LaunchSms(Number, Body);
		}
	}
}
