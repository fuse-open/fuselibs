namespace Alive
{
	/**
		Provides sidebar navigation toggleable by a floating button.

		A menu element must be provided using the `Menu` dependency.

		In most cases, the Drawer sits at the root of the app, enclosing the root Navigator.

		```xml
		<App>
			<JavaScript>
				exports.goToPage1 = function() {
					router.goto("page1");
					drawer.close();
				}

				exports.goToPage2 = function() {
					router.goto("page2");
					drawer.close();
				}
			</JavaScript>

			<Router ux:Name="router" />
			<Alive.Drawer ux:Name="drawer">
            <StackPanel ux:Binding="Menu" ItemSpacing="15" Margin="15">
                <Alive.Body Value="Page 1" Clicked="{goToPage1}" Color="#ABC"/>
                <Alive.Body Value="Page 2" Clicked="{goToPage2}" Color="#CBA"/>
            </StackPanel>
            <Navigator DefaultPath="page1">
                <Page ux:Name="page1" Color="#ABC"/>
                <Page ux:Name="page2" Color="#CBA"/>
            </Navigator>
        </Alive.Drawer>
		</App>
		```

		![actionButton](../../docs/media/alive/drawer.gif)

		Drawer can be opened and closed from JavaScript using the `open()` and `close()` methods.

		```xml
		<JavaScript>
			exports.openDrawer = function() {
				drawer.open();
			}

			exports.closeDrawer = function() {
				drawer.close();
			}
		</JavaScript>

		<Alive.Drawer ux:Name="drawer">
			<Panel ux:Binding="Menu" />
		</Alive.Drawer>
		```

		Drawer displays a floating button above its content that opens the Drawer.
		This can be disabled using the `HideButton` property.

		```xml
		<Alive.Drawer HideButton="true">
			<Panel ux:Binding="Menu" />
		</Alive.Drawer />
		```

		You can combine this property with `WhileActive` to hide the button for certain pages.
		In the example below, the button is hidden while inside `SecondPage`.

		```xml
		<App>
			<Router ux:Name="router" />
			<Alive.Drawer ux:Name="drawer">
				<StackPanel ux:Binding="Menu" ItemSpacing="15" Margin="15">
					<Alive.Body Value="Page 1" Clicked="{goToPage1}" Color="#ABC"/>
					<Alive.Body Value="Page 2" Clicked="{goToPage2}" Color="#CBA"/>
				</StackPanel>
				<Navigator DefaultPath="page1">
					<Page ux:Name="page1" Color="#ABC"/>
					<SecondPage ux:Name="page2" Color="#CBA" drawer="drawer"/>
				</Navigator>

				<Page ux:Class="SecondPage">
					<Alive.Drawer ux:Dependency="drawer" />

					<WhileActive>
						<Change drawer.HideButton="true" />
					</WhileActive>
				</Page>
			</Alive.Drawer>
		</App>
		```

		![actionButton](../../docs/media/alive/drawernobutton.gif)

	*/
	public partial class Drawer {}
}
