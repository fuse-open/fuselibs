namespace Alive
{
	/**
		
		Cards are generally light. Thus, they have an implicit LightTheme by default.
		You can disable this behavior by using its base class, [ThemedCard](api:alive/themedcard) instead.
		
			<Alive.ThemedCard>
				<Alive.DarkTheme />
			</Alive.ThemedCard>
		
		
		Cards are Rectangles, which means they can have children and/or fills.
		
			<Alive.Card Color="Alive.Gray200" />
		
		
		[Alive.ImageFill](api:alive/imagefill) can be used to fill a card with an image.
		
			<Alive.Card>
				<Alive.ImageFill File="Assets/image.jpg" />
			</Alive.Card>
		
		
		[CardMedia](api:alive/cardmedia) can be used to only fill the top of a Card.
		Note: [CardMedia](api:alive/cardmedia) has an implicit [DarkTheme](api:alive/darktheme).
		
		[CardBody](api:alive/cardbody) is a @StackPanel with proper margin and spacing for text content in a Card.
		
			<Alive.Card>
				<StackPanel>
					<Alive.CardMedia>
						<Alive.ImageFill File="Assets/image.jpg" />
					</Alive.CardMedia>
					<Alive.CardBody>
						<Alive.Title>Whee, I'm a card!</Alive.Title>
					</Alive.CardBody>
				</StackPanel>
			</Alive.Card>
	*/
	public partial class Card {}
	
	
	/**
		A [Card](api:alive/card) that takes its background color from the currently active theme.
	*/
	public partial class ThemedCard {}
}
