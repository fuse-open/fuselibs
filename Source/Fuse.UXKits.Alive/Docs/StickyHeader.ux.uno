namespace Alive
{
	/**
		Presents a header above an element that will stick to the top of its enclosing ScrollView
		while in the vertical range of the `StickyHeader`.
		
		**Note:** StickyHeader *must* be placed directly inside the ScrollView's root element.
		This is because `StickyHeader` calculates its own position relative to its parent.
		
			<ScrollView>
				<StackPanel>
					<Alive.StickyHeader>
						<Panel ux:Binding="Header">
							<Alive.Title Margin="15">Header</Alive.Title>
							
							<StackPanel ItemSpacing="20" Margin="20">
								<Alive.Body>Content</Alive.Body>
								<Alive.Body>Content</Alive.Body>
								<Alive.Body>Content</Alive.Body>
								<Alive.Body>Content</Alive.Body>
							</StackPanel>
						</Panel>
					</Alive.StickyHeader>
				</StackPanel>
			</ScrollView>
			
		[MediaScroller](api:alive/mediascroller) wraps a StackPanel around its children,
		and so any StickyHeader must be a direct child of the `MediaScroller` itself.
		
			<Alive.MediaScroller>
				<Panel ux:Binding="Media" />
				
				<Alive.StickyHeader>
					<Panel ux:Binding="Header">
						<Alive.Title Margin="15">Header</Alive.Title>
						
						<!-- content -->
					</Panel>
				</Alive.StickyHeader>
			</Alive.MediaScroller>
			
		See also @StickyHeaderAnimation
	*/
	public partial class StickyHeader {}
}
