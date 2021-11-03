namespace Alive
{
	/**
		A Material Design-like floating action button.

		```xml
		<App>
			<Alive.FallbackTheme />
			<ClientPanel>
				
				<Alive.ActionButton />
			</ClientPanel>
		</App>
		```

		![actionButton](../../docs/media/alive/actionbutton/default.png)

		By deafult, it will take all availabel space of the parrent container. Background color itself is `Transparent` and if you set `Color="Green"`
		
		```xml
		<Alive.ActionButton Color="Green" Size="41"/>
		```
		
		you will see this

		![actionButton](../../docs/media/alive/actionbutton/greenColor.png)

		So you need to set `Size="41"`, because it is a default size of the `red circle`.

		```xml
		<Alive.ActionButton Color="Green" Size="41"/>
		```

		![actionButton](../../docs/media/alive/actionbutton/greenColorResized.png)

		To place it as usually on Android, set the `Alignment="BottomRight"` and `Offset="-25, -50"`

		```xml
		<Alive.ActionButton Alignment="BottomRight" Offset="-25, -50"/>
		```

		![actionButton](../../docs/media/alive/actionbutton/rightbottom.png)

		If you want to add some dynamic to your `ActionButton`, you can add a scaledown effect

		```xml
		<Alive.ActionButton Alignment="BottomRight" Offset="-25, -50">
			<WhilePressed>
				<Scale Factor=".9" Duration=".1"/>
			</WhilePressed>
		</Alive.ActionButton>
		```

		![actionButton](../../docs/media/alive/actionbutton/scaleOnPress.gif)
	*/
	public partial class ActionButton {}
}
