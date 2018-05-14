namespace Alive
{
	/**
		A bordered circle, generally used for profile images.
		
			<Alive.Bubble>
				<Alive.ImageFill File="Assets/image.jpg" />
			</Alive.Bubble>
		
		[Bubbles](api:alive/bubbles) displays a row of partially overlapping Bubbles.
		
			<Alive.Bubbles>
				<Each Items="{friends}">
					<Alive.Bubble>
						<Alive.ImageFill Url="{profileImageUrl}" />
					</Alive.Bubble>
				</Each>
			</Alive.Bubbles>
	*/
	public partial class Bubble {}
}
