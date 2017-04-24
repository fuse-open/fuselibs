This example changes the surrounding panel's color when the @TextInput is
selected.

	<Panel ux:Name="panel" Color="#bbb">
		<TextInput ux:Name="input" PlaceholderText="Name">
			<WhileFocusWithin>
				<Change panel.Color="Green" Duration="0.2"/>
			</WhileFocusWithin>
		</TextInput>
	</Panel>
