namespace Alive
{
	/**
		A bordered circle, generally used for profile images.
		```xml
		<Alive.Bubble>
			<Alive.ImageFill File="Assets/image.jpg" />
		</Alive.Bubble>
		```
		![actionButton](../../media/alive/bubbles/single.png)

		[Bubbles](api:alive/bubbles) displays a row of partially overlapping Bubbles.

		```xml
		<Alive.Bubbles>
            <Alive.Bubble Color="Red">
                <Alive.ImageFill File="profile.jpg"/>
            </Alive.Bubble>
            <Alive.Bubble Color="Yellow">
                <Alive.ImageFill File="profile.jpg"/>
            </Alive.Bubble>
            <Alive.Bubble Color="Green">
                <Alive.ImageFill File="profile.jpg"/>
            </Alive.Bubble>
        </Alive.Bubbles>
		```

		![actionButton](../../media/alive/bubbles/multiple.png)

		or using `Each` for that

		```xml
		<Alive.Bubbles>
			<Each Items="{friends}">
				<Alive.Bubble>
					<Alive.ImageFill Url="{profileImageUrl}" />
				</Alive.Bubble>
			</Each>
		</Alive.Bubbles>
		```
		
	*/
	public partial class Bubble {}
}
