# Button
Buttons are clickable controls that take their look and feel from the @(Theme).

	<App>
		<Button Text="Click me!" ux:Name="button1">
			<Clicked>
				<Set button1.Text="Clicked!" />
			</Clicked>
		</Button>
	</App>

This small example will create a `Button` that covers the whole screen. When you click it, its label will change from "Click me!" to "Clicked!".

In Fuse, pretty much anything can easily be made clickable using @Clicked (and tappable using @Tapped, etc). Thus, if you want to design a custom look and feel for a button, any component can be used:

	<App>
		<Rectangle Fill="#309">
			<Clicked>
				<DebugAction Message="Rectangle got clicked" />
			</Clicked>
		</Rectangle>
	</App>

When you click the rectangle the `Message` output will show up in the Monitor if you are running in preview mode. It will also show up in the standard device logs or, if you started the preview process from the commandline, in the standard console.
