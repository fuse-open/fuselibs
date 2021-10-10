using Uno;
using Uno.UX;
using Fuse.Controls;
using Fuse.Scripting;
using Fuse.Drawing;

namespace Fuse.Triggers.Actions
{
	/**
		`LoadImage` is a trigger action to fetch the image data for the `ImageFill` or `Image`.
		This Trigger action is useful when we set the `AutoLoad` property of the `Image` component or `ImageFill` brush to `false` to make it lazy load,
		and then using this trigger action to actually load it

		## Example

		The following example shows how to use:
		```xml
			<StackPanel>
				<Image ux:Name="img" Url="https://picsum.photos/600/300" AutoLoad="false" Height="200" />
				<Button Text="Load Image">
					<Clicked>
						<LoadImage Image="img" />
					</Clicked>
				</Button>
			</StackPanel>
		```
	*/
	public sealed class LoadImage : TriggerAction
	{

		/**
			The target `ImageFill` brush to load the image
		*/
		public ImageFill ImageFill
		{
			get; set;
		}

		/**
			The target `Image` component to load the image
		*/
		public Image Image
		{
			get; set;
		}

		protected override void Perform(Node target)
		{
			if (Image != null && !Image.AutoLoad && !Image.IsLoaded)
				Image.Load();

			if (ImageFill != null && !ImageFill.AutoLoad && !ImageFill.IsLoaded)
				ImageFill.Load();
		}
	}
}