namespace Alive
{
	/**
		A flat carousel component.

		See [FlatCarouselPage](api:alive/flatcarouselpage) for more on individual page layout.

		```xml
		<Alive.FlatCarousel Color="#BAC">
            <Alive.FlatCarouselPage Title="Page 1">
                <Image Url="https://icons-for-free.com/iconfiles/png/512/profile+profile+page+user+icon-1320186864367220794.png"
                        StretchMode="UniformToFill" />
            </Alive.FlatCarouselPage>
            <Alive.FlatCarouselPage Title="Page 2" Subtitle="Yeah!">
                <Image Url="https://icons-for-free.com/iconfiles/png/512/profile+profile+page+user+icon-1320186864367220794.png"
                        StretchMode="UniformToFill" />
            </Alive.FlatCarouselPage>
        </Alive.FlatCarousel>
		```
		
		![actionButton](../../docs/media/alive/flatcarousel.gif)
		
		See also [Carousel](api:alive/carousel).
	*/
	public partial class FlatCarousel {}

	/**
		A page in a [FlatCarousel](api:alive/flatcarousel).

		FlatCarouselPage displays a gradient above its content.
		Thus, there are two ways to display content above this gradient.

		You can provide a Title and/or Subtitle to be displayed in the bottom-left corner.

		```xml
			<Alive.FlatCarousel>
				<Alive.FlatCarouselPage Title="Page 1">
					<Image File="image.jpg" StretchMode="UniformToFill" />
				</Alive.FlatCarouselPage>
				<Alive.FlatCarouselPage Title="Page 2" Subtitle="Yeah!">
					<Image File="image.jpg" StretchMode="UniformToFill" />
				</Alive.FlatCarouselPage>
			</Alive.FlatCarousel>
		```

		Instead of the default Title/Subtitle setup, you can provide the `Content` template to use a custom element.

		```xml
			<Alive.FlatCarousel>
				<Alive.FlatCarouselPage>
					<Panel ux:Template="Content">
						<Alive.Body>Hello, world</Alive.Body>
					</Panel>
					<Image Url="https://icons-for-free.com/iconfiles/png/512/profile+profile+page+user+icon-1320186864367220794.png"
                        	StretchMode="UniformToFill" />
				</Alive.FlatCarouselPage>
			</Alive.FlatCarousel>
		```
		
		![actionButton](../../docs/media/alive/flatcarousel.png)

	*/
	public partial class FlatCarouselPage {}
}
