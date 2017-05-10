This example shows how we can use the `WhileCanGoBack` and `WhileCanGoForward`
triggers to hide two navigation buttons depending on the page the user is
on:

	<StackPanel Navigation="pageControl">
		<DockPanel>
			<Button Text="Go back" ux:Name="backButton" Visibility="Hidden" Dock="Left">
				<Clicked>
					<GoForward />
				</Clicked>
			</Button>
			<Button Text="Go forward" ux:Name="forwardButton" Visibility="Hidden" Dock="Right">
				<Clicked>
					<GoBack />
				</Clicked>
			</Button>
		</DockPanel>

		<WhileCanGoBack>
			<Change forwardButton.Visibility="Visible" />
		</WhileCanGoBack>

		<WhileCanGoForward>
			<Change backButton.Visibility="Visible" />
		</WhileCanGoForward>

		<PageControl ux:Name="pageControl" Height="1000">
			<Page Color="Red" />
			<Page Color="Green" />
			<Page Color="Blue" />
		</PageControl>
	</StackPanel>
