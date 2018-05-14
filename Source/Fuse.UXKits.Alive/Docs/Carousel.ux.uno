namespace Alive
{
	/**
		A Carousel component with a depth-like effect.
		
			<Alive.Carousel>
				<Alive.CarouselPage>
					<Alive.Card>
						<Alive.ImageFill File="image11.jpg" />
					</Alive.Card>
				</Alive.CarouselPage>
				<Alive.CarouselPage>
					<Alive.Card>
						<Alive.ImageFill File="image2.jpg" />
					</Alive.Card>
				</Alive.CarouselPage>
				<Alive.CarouselPage>
					<Alive.Card>
						<Alive.ImageFill File="image3.jpg" />
					</Alive.Card>
				</Alive.CarouselPage>
			</Alive.Carousel>
			
			
		See also [FlatCarousel](api:alive/flatcarousel).
	*/
	public partial class Carousel {}
	
	/**
		A page in a [Carousel](api:alive/carousel).
		Provides no visuals, only animation.
		
			<Alive.Carousel>
				<Alive.CarouselPage>
					<Alive.Card>
						<Alive.ImageFill File="image11.jpg" />
					</Alive.Card>
				</Alive.CarouselPage>
				<Alive.CarouselPage>
					<Alive.Card>
						<Alive.ImageFill File="image2.jpg" />
					</Alive.Card>
				</Alive.CarouselPage>
				<Alive.CarouselPage>
					<Alive.Card>
						<Alive.ImageFill File="image3.jpg" />
					</Alive.Card>
				</Alive.CarouselPage>
			</Alive.Carousel>
	*/
	public partial class CarouselPage {}
}
