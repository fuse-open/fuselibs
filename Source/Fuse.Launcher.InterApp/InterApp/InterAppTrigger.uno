using Uno;
using Uno.Net.Http;

namespace Fuse.Triggers.Actions
{
	/** Launch the default browser for an URL or open files with its corresponding default application

		You'll find this trigger action in the Fuse.Launcher package, which have to be referenced from your uno project.
		For example:
		```JSON
			{
				"Packages": [
					"Fuse",
					"FuseJS",
					"Fuse.Launcher"
				]
			}
		```

		## Example
		```XML
			<StackPanel Margin="20">
				<Button Margin="10" Text="Go to Fusetools">
					<Clicked>
						<LaunchUri Uri="https://www.fusetools.com/" />
					</Clicked>
				</Button>
			</StackPanel>
		```

		Note: you can pass any URI string to `LaunchUri`, but how it is handled will depend on the target platform and particular device settings.

		There are several common URI schemes that you can use on both Android and iOS:
			http://<website address>
			https://<website address>
			tel:<phone number>
			sms:<phone number>

		Other platform-specific URI schemes are known to be working fine, for example `geo:<parameters>` launches Maps application on Android
		and `facetime:<parameters>` launches a Facetime video call on iOS.
		More information on supported URI schemes: [on Android](https://developer.android.com/guide/components/intents-common.html) and [on iOS](https://developer.apple.com/library/content/featuredarticles/iPhoneURLScheme_Reference/Introduction/Introduction.html).
	*/
	public class LaunchUri : TriggerAction
	{
		public string Uri {get; set;}

		protected override void Perform(Node target)
		{
			Fuse.LauncherImpl.InterAppLauncher.LaunchUri(new Uri(this.Uri));
		}
	}
	
	public class LaunchApp : TriggerAction
	{
		public string Uri {get; set;}
		public string AppStoreUri {get; set;}

		protected override void Perform(Node target)
		{
			Fuse.LauncherImpl.InterAppLauncher.LaunchApp(this.Uri, this.AppStoreUri);
		}
	}
}
