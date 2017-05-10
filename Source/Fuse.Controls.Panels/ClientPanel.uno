
namespace Fuse.Controls
{
	/** `ClientPanel` compensates for space taken up by the on-screen keyboard, status bar,
		and other OS-specific elements at the top and bottom edges of the screen.
		
		It is essentially a @DockPanel with a @StatusBarBackground and a @BottomBarBackground docked to its top and bottom edges, respectively.
		
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
			<DockPanel>
				<StatusBarBackground Dock="Top" />
				
				<!-- Our app's content -->
				
				<BottomBarBackground Dock="Bottom" />
			</DockPanel>
		</App>
		```
	*/
	public partial class ClientPanel
	{

	}
}