namespace Alive
{
	/**
		A colored circle, generally used to communicate category.

		```xml
		<Alive.Donut StrokeColor="{Resource Alive.Red}" />
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
							<Alive.Donut StrokeColor="{Resource Alive.Red}" />
							<Text Value="Catigory - {index()}" Color="White"/>
						</StackPanel>
					</Each>            
				</StackPanel>
			</ClientPanel> 
		</App>
		```

		![actionButton](../../docs/media/alive/donut.png)

		See also [ColorBadge](api:alive/colorbadge)
	*/
	public partial class Donut {}
}
