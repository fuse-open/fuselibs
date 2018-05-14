namespace Alive
{
	/**
		The underlying animation used to implement [StickyHeader](api:alive/stickyheader).
		
		StickyHeaderAnimation makes the provided `Header` stick to the top of a ScrollView,
		while within the vertical range of its parent element.
		
		**Note:** `Header` *must* be a direct child of the parent element of the StickyHeaderAnimation,
		and the parent element must be a direct child of the @ScrollView's root child element.
		
			<ScrollView>
				<StackPanel>
					<Each Count="5">
						<StackPanel>
							<Panel ux:Name="header" Height="60" />
							<Alive.StickyHeaderAnimation Header="header" />
							
							<!-- content -->
						</StackPanel>
					</Each>
				</StackPanel>
			</ScrollView>
	*/
	public partial class StickyHeaderAnimation {}
}
