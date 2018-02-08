
namespace Fuse.Controls
{
	/** `ClientPanel` compensates for space taken up by the on-screen keyboard, status bar,
		and other OS-specific elements at the top and bottom edges of the screen.
		
		It is a @DockPanel with a `Padding` to fill in the edge regions. You should not modify any properties of the `ClientPanel`, but only add Children. Adding a `Dock` property to the children is okay.
		
		The following snippets are essentially equal:
		
		```
		<App>
			<ClientPanel>
				<!-- Our app's content -->
			</ClientPanel>
		</App>
		```
		
		```
		<App>
			<DockPanel Padding="window().safeMargins">
				<!-- Our app's content -->
			</DockPanel>
		</App>
		```
		
		You don't need to use a `DockPanel` in this second example unless you intend on using `Dock` on the children.
		
		For finer control of margins you can use `window().safeMargins`, or `window().staticMargins` on individual children.
	*/
	public partial class ClientPanel
	{

	}
}