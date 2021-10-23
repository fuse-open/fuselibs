namespace Alive
{
	/**
		Presents a header above an element that will stick to the top of its enclosing ScrollView
		while in the vertical range of the `StickyHeader`.

		**Note:** StickyHeader *must* be placed directly inside the ScrollView's root element.
		This is because `StickyHeader` calculates its own position relative to its parent.

		```xml
		<App >
		    <Rectangle ux:Class="Body" Color="#cea" Size="100%, 300" >
		        <Text TextWrapping="Wrap" ClipToBounds="true">
		            Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor.
		Maecenas sed diam eget risus varius blandit sit amet non magna.
		Donec id elit non mi porta gravida at eget metus. Fusce dapibus,
		tellus ac cursus commodo
		        </Text>
		    </Rectangle>

		    <Alive.FallbackTheme />
		    <ScrollView>
		        <StackPanel>
		            <Alive.StickyHeader>
		                <Panel ux:Binding="Header" Color="#aaa">
		                    <Alive.Title Margin="15">Header 1</Alive.Title>
		                </Panel>
		                <Body />
		            </Alive.StickyHeader>
		            <Alive.StickyHeader>
		                <Panel ux:Binding="Header" Color="#aba">
		                    <Alive.Title Margin="15">Header 2</Alive.Title>
		                </Panel>
		                <Body />
		            </Alive.StickyHeader>
		            <Alive.StickyHeader>
		                <Panel ux:Binding="Header" Color="#caa">
		                    <Alive.Title Margin="15">Header 3</Alive.Title>
		                </Panel>
		                <Body />
		            </Alive.StickyHeader>
		        </StackPanel>
		    </ScrollView>
		</App>
		```

		![actionButton](../../docs/media/alive/stickyheader.gif)

		[MediaScroller](api:alive/mediascroller) wraps a StackPanel around its children,
		and so any StickyHeader must be a direct child of the `MediaScroller` itself.

		```xml
		<Alive.MediaScroller>
        <Panel ux:Binding="Media" />

        <Alive.StickyHeader>
            <Panel ux:Binding="Header" Color="#aba">
                <Alive.Title Margin="15">Header 1</Alive.Title>
            </Panel>
            <Body /> <!-- from examle above  -->
        </Alive.StickyHeader>
        <Alive.StickyHeader>
            <Panel ux:Binding="Header" Color="#aba">
                <Alive.Title Margin="15">Header 2</Alive.Title>
            </Panel>
            <Body />
        </Alive.StickyHeader>
        <Alive.StickyHeader>
            <Panel ux:Binding="Header" Color="#caa">
                <Alive.Title Margin="15">Header 3</Alive.Title>
            </Panel>
            <Body />
        </Alive.StickyHeader>
    </Alive.MediaScroller>
		```

		See also @StickyHeaderAnimation
	*/
	public partial class StickyHeader {}
}
