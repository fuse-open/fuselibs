using Fuse.Triggers;
using Fuse.Triggers.Actions;
using Uno.UX;
namespace Fuse
{
	/** Play bundled .wav files

		This is intended for playing the small one-shot sounds like button-clicks & notification chimes.

		You'll find this trigger action in the Fuse.Audio package, which have to be referenced from your Uno project file.
		For example:

			{
				"Packages": [
					"Fuse",
					"FuseJS",
					"Fuse.Audio"
				]
			}

		## Example

			<StackPanel Margin="20">
				<Button Margin="10" Text="Test Sound">
					<Clicked>
						<PlaySound File="chime.wav" />
					</Clicked>
				</Button>
			</StackPanel>
	*/
	public class PlaySound : TriggerAction
	{
		public FileSource File
		{
			get; set;
		}

		extern(!Android && !iOS && !(HOST_WINDOWS && DOTNET))
		protected override void Perform(Node n)
		{
			Fuse.Diagnostics.UserWarning("Sound Effect Playback is not yet implemented for this platform", this);
		}

		extern(Android || iOS || (HOST_WINDOWS && DOTNET))
		protected override void Perform(Node n)
		{
			if(File == null) return;
			var bundleFileSource = File as BundleFileSource;
			if (bundleFileSource != null)
				Fuse.Audio.SoundPlayer.PlaySoundFromBundle(bundleFileSource);
			else
				Fuse.Audio.SoundPlayer.PlaySoundFromByteArray(File.ReadAllBytes());
		}
	}
}
