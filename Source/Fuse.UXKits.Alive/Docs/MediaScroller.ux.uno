namespace Alive
{
	/**
		A scrolling container with a header image.
		
		MediaScroller requires you to provide a `Media` element.
		This is the main image that will be displayed above the rest of the content.
		Note that we use `ux:Binding` here instead of `ux:Template`.
		This is because `Media` is a [dependency](articles:ux-markup/dependencies), and must always be provided.
		
			<Alive.MediaScroller>
				<Image ux:Binding="Media" File="image.jpg" Height="250" />
				
				<!-- content goes here -->
			</Alive.MediaScroller>
		
		Any element that is not a `ux:Template` or `ux:Dependency` is placed in a @StackPanel that serves
		as the main content of the inner @ScrollView.
		
			<Alive.MediaScroller>
				<Image ux:Binding="Media" File="image.jpg" Height="250" />
				
				<Alive.Body Value="children" />
				<Alive.Body Value="will" />
				<Alive.Body Value="be" />
				<Alive.Body Value="stacked" />
				<Alive.Body Value="vertically" />
			</Alive.MediaScroller>

		When the user scrolls downwards, the `Media` element shrinks with the scrolling motion,
		until it has the same height as `TopBar`.
		
			<Alive.MediaScroller>
				<Panel ux:Template="TopBar">
					<Alive.Body Alignment="Center" Margin="0,20">
						This is the title!
					</Alive.Body>
				</Panel>
				<Image ux:Binding="Media" File="image.jpg" Height="250" />
			</Alive.MediaScroller>
		
		You may specify a color to fade in while `Media` morphs into `TopBar` using the `TopBarColor` property.

			<Alive.MediaScroller TopBarColor="{Resource Alive.AccentColor}">
				<Panel ux:Template="TopBar" Height="56" />
				<Image ux:Binding="Media" File="image.jpg" Height="250" />
			</Alive.MediaScroller>
			
		When the user scrolls above the scrollable area, the `Media` element will be pixel-stretched in accordance.
		To avoid this, you may also specfy a `MediaOverlay` template.
		This is useful for content with sharp edges (such as text).
		
			<Alive.MediaScroller TopBarColor="{Resource Alive.AccentColor}">
				<Panel ux:Template="MediaOverlay">
					<Alive.Card Margin="20">
						<Alive.ImageFill File="image.jpg" />
					</Alive.Card>
				</Panel>
				<Panel ux:Binding="Media" Color="{Resource Alive.PrimaryBackgroundColor}" />
			</Alive.MediaScroller>
			
		`MediaOverlay` is displayed below the fading colored overlay.
		You may provide the `BottomBar` template to display an element on top of this overlay,
		aligned to bottom of `Media`.
		
			<Alive.MediaScroller TopBarColor="{Resource Alive.AccentColor}">
				<Panel ux:Template="MediaOverlay">
					<Alive.Card Margin="20">
						<Alive.ImageFill File="image.jpg" />
					</Alive.Card>
				</Panel>
				<Panel ux:Binding="Media" Color="{Resource Alive.PrimaryBackgroundColor}" />
			</Alive.MediaScroller>
	*/
	public partial class MediaScroller {}
}
