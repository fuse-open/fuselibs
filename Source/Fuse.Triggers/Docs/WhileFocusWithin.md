This example changes the surrounding @StackPanel's color when a @TextInput is
selected.

	<StackPanel ux:Name="panel" Color="#bbb">
		<TextInput PlaceholderText="Name" />
		<TextInput PlaceholderText="Age" />
		<TextInput PlaceholderText="Address" />
		<WhileFocusWithin>
			<Change panel.Color="Green" Duration="0.2"/>
		</WhileFocusWithin>
	</StackPanel>
