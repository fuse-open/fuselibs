# Common properties

## HitTestMode

When interacting with an element, it is sometimes desirable to be able to differentiate which elements can be interacted with and how. This is typically referred to as "hit testing". In Fuse, how elements interact with user input can be set using `HitTestMode`.

### Example
This example will layout two `Rectangle`s and add `Clicked`-triggers to both of them. However, only the left one will output anything when clicked, as the hit testing has been explicitly disabled on the right rectangle:

	<Grid ColumnCount="2">
		<Rectangle Width="100" Height="100" Fill="#808" >
			<Clicked>
				<DebugAction Message="Clicked left" />
			</Clicked>
		</Rectangle>
		<Rectangle Width="100" Height="100" Fill="#808" HitTestMode="None" >
			<Clicked>
				<DebugAction Message="Clicked right" />
			</Clicked>
		</Rectangle>
	</Grid>
	
 This can be very helpful if you have visual elements obscuring elements below it, where you want the lower elements respond to input.

## ClipToBounds

Normally, when laying out an element inside the other, the inner element can freely live outside the parent element:

	<Panel Width="100" Height="100">
			<Image Margin="-100" File="Pictures/Picture1.jpg"
				StretchMode="UniformToFill" />
	</Panel>

This `Image` will appear to be 300pt wide and tall, as the `Panel` doesn't clip children to its bounds.

If you intend to have the `Image` clip to its parent size, simply set `ClipToBounds="true"` on the `Panel`:

		<Panel Width="100" Height="100" ClipToBounds="true">
			<Image Margin="-100" File="Pictures/Picture1.jpg"
				StretchMode="UniformToFill" />
		</Panel>

Now, the `Image` will not overflow the bounds of the `Panel`.

## Opacity

You can set the transparency of objects using the `Opacity`-property. When `Opacity="0"`, the element is completely transparent.

### Example

In this example, a panel's opacity is set to 0.5

	<Panel>
		<Opacity Value="0.5" />
	</Panel>

## Layers

It is often helpful to redefine what existing controls should look like. Elements that are added to containers can be assigned to different layers. If you want a button to appear with a red background, you can redefine its `Background` `Layer`:

	<Button Text="Hello!">
		<Rectangle Fill="#931" Layer="Background" />
	</Button>

This will not change the layout or behavior of the @Button, but its appearance will change.
