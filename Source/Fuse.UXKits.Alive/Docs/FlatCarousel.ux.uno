namespace Alive
{
	/**
		A flat carousel component.
		
		See [FlatCarouselPage](api:alive/flatcarouselpage) for more on individual page layout.
		
			<Alive.FlatCarousel>
				<Alive.FlatCarouselPage Title="Page 1">
					<Image File="image.jpg" StretchMode="UniformToFill" />
				</Alive.FlatCarouselPage>
				<Alive.FlatCarouselPage Title="Page 2" Subtitle="Yeah!">
					<Image File="image.jpg" StretchMode="UniformToFill" />
				</Alive.FlatCarouselPage>
			</Alive.FlatCarousel>
		
		See also [Carousel](api:alive/carousel).
	*/
	public partial class FlatCarousel {}
	
	/**
		A page in a [FlatCarousel](api:alive/flatcarousel).
		
		FlatCarouselPage displays a gradient above its content.
		Thus, there are two ways to display content above this gradient.
		
		You can provide a Title and/or Subtitle to be displayed in the bottom-left corner.
		
			<Alive.FlatCarousel>
				<Alive.FlatCarouselPage Title="Page 1">
					<Image File="image.jpg" StretchMode="UniformToFill" />
				</Alive.FlatCarouselPage>
				<Alive.FlatCarouselPage Title="Page 2" Subtitle="Yeah!">
					<Image File="image.jpg" StretchMode="UniformToFill" />
				</Alive.FlatCarouselPage>
			</Alive.FlatCarousel>
		
		Instead of the default Title/Subtitle setup, you can provide the `Content` template to use a custom element.
		
			<Alive.FlatCarousel>
				<Alive.FlatCarouselPage>
					<Panel ux:Template="Content">
						<Alive.Body>Hello, world</Alive.Body>
					</Panel>
					<Image File="image.jpg" StretchMode="UniformToFill" />
				</Alive.FlatCarouselPage>
			</Alive.FlatCarousel>
	*/
	public partial class FlatCarouselPage {}
}
