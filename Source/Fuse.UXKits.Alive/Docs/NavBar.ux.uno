namespace Alive
{
	/**
		A navigation bar including @StatusBarBackground.
		Children are placed inside a DockPanel.

		Use [NavBarTitle](api:alive/navbartitle) for title text in a `NavBar`.
		
		```xml
		<DockPanel>
			<Alive.NavBar Dock="Top">
				<Alive.BackButton Dock="Left" />
				<Alive.NavBarTitle Alignment="Center">Page</Alive.NavBarTitle>
			</Alive.NavBar>
		</DockPanel>
		```

		![actionButton](../../docs/media/alive/navbar.png)
	*/
	public partial class NavBar {}
}
