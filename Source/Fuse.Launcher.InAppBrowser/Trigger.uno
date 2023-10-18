using Uno;

namespace Fuse.Triggers.Actions
{

	/** Launch the default map app

		You'll find this trigger action in the Fuse.Launcher package, which have to be referenced from your uno project.
		For example:

		```json
			{
				"references": [
					"Fuse",
					"FuseJS",
					"Fuse.Launcher"
				]
			}
		```

		## Example

		```xml
			<StackPanel Margin="20">
				<Button Margin="10" Text="Launch InApp Browser">
					<Clicked>
						<LaunchInAppBrowser Url="https://fuseopen.com" />
					</Clicked>
				</Button>
			</StackPanel>
		```
	*/
	public class LaunchInAppBrowser : TriggerAction
	{
		public string Url {get; set;}

		protected override void Perform(Node target)
		{
			Fuse.LauncherImpl.InAppBrowserLauncher.LaunchInAppBrowser(Url);
		}
	}
}
