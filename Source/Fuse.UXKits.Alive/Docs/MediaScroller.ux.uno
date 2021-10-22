namespace Alive
{
	/**
		A scrolling container with a header image.

		MediaScroller requires you to provide a `Media` element.
		This is the main image that will be displayed above the rest of the content.
		Note that we use `ux:Binding` here instead of `ux:Template`.
		This is because `Media` is a [dependency](articles:ux-markup/dependencies), and must always be provided.

		```xml
		<Panel Color="#eee">
        <Alive.MediaScroller Width="90%" Color="#ACC">
            <Image ux:Binding="Media" 
                    Url="https://icons-for-free.com/iconfiles/png/512/profile+profile+page+user+icon-1320186864367220794.png"
                    Height="250" />
                    <!-- <Alive.Body Value="children" /> -->
        </Alive.MediaScroller> 
		```

		![actionButton](../../docs/media/alive/mediascroller/imageonly.png)

		Any element that is not a `ux:Template` or `ux:Dependency` is placed in a @StackPanel that serves
		as the main content of the inner @ScrollView.

		```xml
		<Panel Color="#eee">
			<Alive.MediaScroller Width="90%" Color="#ACC">
				<Image ux:Binding="Media" 
						Url="https://icons-for-free.com/iconfiles/png/512/profile+profile+page+user+icon-1320186864367220794.png"
						Height="250" />
				<Alive.Body Value="children" />
				<Alive.Body Value="will" />
				<Alive.Body Value="be" />
				<Alive.Body Value="stacked" />
				<Alive.Body Value="vertically" />
			</Alive.MediaScroller>
		</Panel> 
		```

		![actionButton](../../docs/media/alive/mediascroller/children.png)

		When the user scrolls downwards, the `Media` element shrinks with the scrolling motion,
		until it has the same height as `TopBar`.

		```xml
			<Alive.MediaScroller>
				<Panel ux:Template="TopBar">
					<Alive.Body Alignment="Center" Margin="0,20">
						This is the title!
					</Alive.Body>
				</Panel>
				<Image ux:Binding="Media" File="image.jpg" Height="250" />
			</Alive.MediaScroller>
		```

		You may specify a color to fade in while `Media` morphs into `TopBar` using the `TopBarColor` property.

		```xml
		<Panel Color="#eee">
			<Alive.MediaScroller Width="90%" Color="#ACC" TopBarColor="{Resource Alive.AccentColor}">
				<Panel ux:Template="TopBar">
					<Alive.Body Alignment="Center" Margin="0,20">
						This is the title!
					</Alive.Body>
				</Panel>
				<Image ux:Binding="Media" 
						Url="https://icons-for-free.com/iconfiles/png/512/profile+profile+page+user+icon-1320186864367220794.png"
						Height="250" />
			</Alive.MediaScroller>
		</Panel> 
		```

		![actionButton](../../docs/media/alive/mediascroller/motion1.gif)

		When the user scrolls above the scrollable area, the `Media` element will be pixel-stretched in accordance.
		To avoid this, you may also specfy a `MediaOverlay` template.
		This is useful for content with sharp edges (such as text).

		```xml
		<Alive.MediaScroller Width="90%" Color="#ACC" TopBarColor="{Resource Alive.AccentColor}">
            <Panel ux:Template="MediaOverlay">
                <Alive.Card Margin="20" Size="150">
                    <Alive.ImageFill  Url="https://icons-for-free.com/iconfiles/png/512/profile+profile+page+user+icon-1320186864367220794.png"/>
                </Alive.Card>
            </Panel>
            <Panel ux:Binding="Media" Color="{Resource Alive.PrimaryBackgroundColor}" />
        </Alive.MediaScroller>
		```

		![actionButton](../../docs/media/alive/mediascroller/motion2.gif)

		`MediaOverlay` is displayed below the fading colored overlay.
		You may provide the `BottomBar` template to display an element on top of this overlay,
		aligned to bottom of `Media`.

		```xml
			<Alive.MediaScroller TopBarColor="{Resource Alive.AccentColor}">
				<Panel ux:Template="MediaOverlay">
					<Alive.Card Margin="30" Size="100">
						<Alive.ImageFill  Url="https://icons-for-free.com/iconfiles/png/512/profile+profile+page+user+icon-1320186864367220794.png"/>
					</Alive.Card>
				</Panel>
				<Panel ux:Binding="Media" Color="{Resource Alive.PrimaryBackgroundColor}" />

				<Panel ux:Template="BottomBar" Margin="20,0">
					<Text Value="This is a bottom bar" Color="White"/>
				</Panel>
			</Alive.MediaScroller>
		```
		
		![actionButton](../../docs/media/alive/mediascroller/bottom.png)

	*/
	public partial class MediaScroller {}
}
