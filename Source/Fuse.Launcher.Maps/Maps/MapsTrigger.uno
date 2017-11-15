using Uno;
using Uno.Net.Http;

namespace Fuse.Triggers.Actions
{

	/** Launch the default map app

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
				<Button Margin="10" Text="Launch Maps">
					<Clicked>
						<LaunchMaps Latitude="59.9139" Longitude="10.7522" />
					</Clicked>
				</Button>
			</StackPanel>
	*/
	public class LaunchMaps : TriggerAction
	{
		public string Latitude {get; set;}
		public string Longitude {get; set;}

		protected override void Perform(Node target)
		{
			double lat = 0;
			double lon = 0;
			if (Double.TryParse(Latitude, out lat) && Double.TryParse(Longitude, out lon))
				Fuse.LauncherImpl.MapsLauncher.LaunchMaps(lat, lon);
		}
	}
}
