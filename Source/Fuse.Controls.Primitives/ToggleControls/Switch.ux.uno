namespace Fuse.Controls
{
	/** Displays a switch

		A switch implemented with @ToggleControl. The platform
		native switch will be displayed if used in NativeViewHost.

		## Example

			<StackPanel>
				<Switch ux:Name="_sw">
					<WhileTrue Value="{ReadProperty _sw.Value}">
						<DebugAction Message="Switch.Value = true" />
					</WhileTrue>
				</Switch>
				<NativeViewHost>
					<Switch />
				</NativeViewHost>
			</StackPanel>		

	*/
	public partial class Switch
	{

	}
}