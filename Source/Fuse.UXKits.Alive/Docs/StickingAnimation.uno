namespace Alive
{
	/**
		Animation that progresses as a [StickyHeader](api:alive/stickyheader) begins sticking,
		within to a given distance.
		
		Not to be confused with [StickyHeaderAnimation](api:alive/stickyheaderanimation).
		
		The `Distance` property determines the distance from where the header starts sticking that must be scrolled,
		for the animation to progress from start to finish.
		
			<ScrollView>
				<StackPanel>
					<Alive.StickyHeader>
						<Panel ux:Binding="Header" Height="60" Color="{Resource Alive.AccentColor}">
							<Shadow ux:Name="shadow" Size="0" />
						</Panel>
						<Alive.StickingAnimation Distance="60">
							<Change shadow.Size="1" />
						</Alive.StickingAnimation>
					</Alive.StickyHeader>
				</StackPanel>
			</ScrollView>
	*/
	public partial class StickyHeaderAnimation {}
}
