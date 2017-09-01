
namespace Fuse.Controls
{
	/** Displays a block of text.

	@include Docs/Text/Brief.md

	@include Docs/Text/Examples.md

	@include Docs/Text/Remarks.md

	@seealso Fuse.Controls.TextInput	
	@seealso Fuse.Font
	*/	
	public class Text: TextControl
	{
		/** @experimental Does text shaping on a background thread.

		This can be useful if your app has a lot of text since the
		initial loading time for such an app's text elements can be too
		high to do without a noticable delay.

		If this property is set to true, the @WhileLoading trigger is
		active while the text is loading.

		## Example

		The following code displays a green background while a piece of
		text is loading on the background thread, and fades in the text
		when it's available.

			<Panel ux:Name="_loading" Background="#0F0" Opacity="0.0"/>
			<Text ux:Name="_text" Value="Some text" LoadAsync="true" >
				<WhileLoading>
					<Change _loading.Opacity="1.0" Duration="0.5" />
					<Change _text.Opacity="0.0"  Duration="0.5" />
				</WhileLoading>
			</Text>

		## Remarks

		This property currently only works when running on an actual
		device and using the Harbuzz text renderer (enabled on desktop
		or by building for device with `-DUSE_HARFBUZZ`).

		*/
		public bool LoadAsync
		{
			get { return InternalLoadAsync; }
			set { InternalLoadAsync = value; }
		}
	}
}
