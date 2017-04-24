This example shows how we can use @WhileEnabled and @WhileDisabled inside a
panel to react to its state:

	<StackPanel>
		<Panel ux:Name="panel" Width="50" Height="50" Background="Red" >
			<WhileEnabled>
				<Rotate Degrees="45" Duration="0.5"/>
			</WhileEnabled>
			<WhileDisabled>
				<Change text.Value="Disabled" />
			</WhileDisabled>
		</Panel>
		<Text ux:Name="text">Enabled</Text>
		<WhileFalse ux:Name="isEnabled">
			<Change panel.IsEnabled="False" />
		</WhileFalse>
		<Button Text="Toggle">
			<Clicked>
				<Toggle Target="isEnabled" />
			</Clicked>
		</Button>
	</StackPanel>
