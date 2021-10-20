namespace Alive
{
	/**
		A horizontal rectangle, generally used to communicate category using color.

		```xml
		<Alive.ColorBadge Color="{Resource Alive.Blue}" />
		```

		Possible usage

		```xml
		<App>
			<Alive.FallbackTheme />
			<ClientPanel>
				<StackPanel ItemSpacing="10" Alignment="Center">
					<Text Value="Categories list:" Color="White"/>
					<Each Count="5">
						<StackPanel Orientation="Horizontal" ItemSpacing="10" Margin="25,0">
							<Alive.ColorBadge />
							<Text Value="Catigory - {index()}" Color="White"/>
						</StackPanel>
					</Each>            
				</StackPanel>
			</ClientPanel> 
		</App>
		```

		![actionButton](../../../media/alive/colorbadge.png)

		> **Note** Color can be changed only by overriding an AccentColor of the Theme
		
		See also [Donut](api:alive/donut).
	*/
	public partial class ColorBadge {}
}
