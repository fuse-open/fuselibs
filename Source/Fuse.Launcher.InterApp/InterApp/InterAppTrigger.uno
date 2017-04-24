using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Net.Http;
using Fuse.Animations;
using Fuse.Triggers.Actions;

namespace Fuse.Triggers.Actions
{
	/** Launch the default browser for an URL or open files with its corresponding default application

		You'll find this trigger action in the Fuse.Launcher package, which have to be referenced from your uno project.
		For example:

			{
				"Packages": [
					"Fuse",
					"FuseJS",
					"Fuse.Launcher"
				]
			}

		## Example

			<StackPanel Margin="20">
				<Button Margin="10" Text="Go to Fusetools">
					<Clicked>
						<LaunchUri Uri="https://www.fusetools.com/" />
					</Clicked>
				</Button>
			</StackPanel>
	*/
	public class LaunchUri : TriggerAction
	{
		public string Uri {get; set;}

		protected override void Perform(Node target)
		{
			Fuse.LauncherImpl.InterAppLauncher.LaunchUri(new Uri(this.Uri));
		}
	}
}
