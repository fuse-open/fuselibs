This example changes the background color to white when it is possible to
scroll down.

	<ScrollView>
		<SolidColor ux:Name="color" Color="#000"/>
		<StackPanel Margin="10">
			<Each Count="10">
				<Panel Height="200" Background="Red" Margin="2"/>
			</Each>
		</StackPanel>
		<WhileScrollable ScrollDirections="Down">
			<Change color.Color="#ddd" Duration="0.4"/>
		</WhileScrollable>
	</ScrollView>
