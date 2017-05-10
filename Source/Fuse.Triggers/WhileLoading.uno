using Uno;
using Uno.Collections;
using Uno.UX;
using Fuse.Animations;

namespace Fuse.Triggers
{
	/** Active while a resource in the surrounding context is loading.

		This trigger can be used inside a @Video, @Image, or @Text element.

		## Example

		The following example will display some text while an image resource is loading via URL:

			<StackPanel>
				<Image Url="https://upload.wikimedia.org/wikipedia/commons/f/f1/Kitten_and_partial_reflection_in_mirror.jpg">
					<WhileLoading>
						<Change showLoadingText.Value="True" />
					</WhileLoading>
				</Image>

				<WhileTrue ux:Name="showLoadingText">
					<Text>Image is loading...</Text>
				</WhileTrue>
			</StackPanel>

		@examples Docs/VideoTriggers.md
		
		`<WhileLoading>` is equivalent to `<WhileBusy Activity="Loading">`.
	*/
	public class WhileLoading : WhileBusy
	{
		public WhileLoading()
		{
			Activity = BusyTaskActivity.Loading;
		}
	}
}
