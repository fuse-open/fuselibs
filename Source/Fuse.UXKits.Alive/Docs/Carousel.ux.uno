namespace Alive
{
	/**
		A Carousel component with a depth-like effect.
		
		```xml
		<Alive.Carousel>
			<Alive.CarouselPage>
				<Alive.Card>
					<Alive.ImageFill Url="https://icons-for-free.com/iconfiles/png/512/profile+profile+page+user+icon-1320186864367220794.png" />
				</Alive.Card>
			</Alive.CarouselPage>
			<Alive.CarouselPage>
				<Alive.Card>
					<Alive.ImageFill Url="https://icons-for-free.com/iconfiles/png/512/profile+profile+page+user+icon-1320186864367220794.png" />
				</Alive.Card>
			</Alive.CarouselPage>
			<Alive.CarouselPage>
				<Alive.Card>
					<Alive.ImageFill Url="https://icons-for-free.com/iconfiles/png/512/profile+profile+page+user+icon-1320186864367220794.png"/>
				</Alive.Card>
			</Alive.CarouselPage>
		</Alive.Carousel>
		```

		![actionButton](../../docs/media/alive/carousel.png)

		See also [FlatCarousel](api:alive/flatcarousel).
	*/
	public partial class Carousel {}

	/**
		A page in a [Carousel](api:alive/carousel).
		Provides no visuals, only animation.
		
		```xml
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
		```

	*/
	public partial class CarouselPage {}
}
