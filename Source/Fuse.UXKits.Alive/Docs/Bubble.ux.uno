namespace Alive
{
	/**
		A bordered circle, generally used for profile images.

		```xml
		<Alive.Bubble>
			<Alive.ImageFill Url="https://icons-for-free.com/iconfiles/png/512/profile+profile+page+user+icon-1320186864367220794.png" />
		</Alive.Bubble>
		```

		![actionButton](../../../media/alive/bubbles/single.png)

		[Bubbles](api:alive/bubbles) displays a row of partially overlapping Bubbles.

		```xml
		<Alive.Bubbles>
            <Alive.Bubble Color="Red">
                <Alive.ImageFill Url="https://icons-for-free.com/iconfiles/png/512/profile+profile+page+user+icon-1320186864367220794.png" />
            </Alive.Bubble>
            <Alive.Bubble Color="Yellow">
                <Alive.ImageFill Url="https://icons-for-free.com/iconfiles/png/512/profile+profile+page+user+icon-1320186864367220794.png" />
            </Alive.Bubble>
            <Alive.Bubble Color="Green">
                <Alive.ImageFill Url="https://icons-for-free.com/iconfiles/png/512/profile+profile+page+user+icon-1320186864367220794.png" />
            </Alive.Bubble>
        </Alive.Bubbles>
		```
		
		![actionButton](../../../media/alive/bubbles/multiple.png)

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
