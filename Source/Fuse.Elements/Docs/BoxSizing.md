The @(Element.BoxSizing:box sizing) algorithm is what converts the various layout properties, such as `Width`, `MaxHeight`, `Alignment`, into an actual position and size. As the `Standard` setting is general purpose, you generally only change the `BoxSizing` mode in special layouts.

- `Standard` is the common layout model. This interprets the layout properties basically as they are described.
- `NoImplicitMax` is a small modification to the `Standard` model. This removes the implied limits of `MaxWidth="100%"` and `MaxHeight="100%"`. This is useful to create oversized elements which should not be limited by their parent size.
- `Limit` uses the basic model of `Standard` but then restricts the final size. This is primarily used for sliding panels, or overhanging elements.
- `FillAspect` enforces an aspect ratio on the size of the element. It is used when the aspect is most important sizing consideration, such as creating a square grid.
- `LayoutMaster` should not be used directly, it is set implicitly when setting the @Element.LayoutMaster property.


## Standard

The standard layout rules interpret the layout properties fairly directly.

By default elements are expanded in both directions to fill the available space. An element that has an explicit `Width` or `Height` will be not be expanded to fill its parent in that dimension. An element that has an explicit `Alignment` will not be expanded in the direction of the alignment (for example `Left` will not stretch horizontally, but still verticall,y whereas `Center` will not expand in either direction). When an element is not expanded it will use with the explicit size (`Width` or `Height`) or use the natural size (enough to contain itself and its children).

Elements have an implied `MaxWidth` and `MaxHeight` of `100%`.


## NoImplicitMax

This works like `Standard` but removes the implied `MaxWidth` and `MaxHeight`.

This is useful for elements that are generally larger than their parent. Usually this is for adding panels beside an element, or decorations near an element.

	<Panel Alignment="Center">
		<Text Value="A Notice"/>
		<Image BoxSizing="NoImplicitMax" File="star.png" Alignment="TopLeft" Anchor="50%,50%"/>
	</Panel>
	
This creates a text label with a star in the upper-left corner. The `BoxSizing="NoImplicitMax"` ensures that the star is it's natural size even if the label is smaller than it.


## Limit

`Limit` allows you to restrict the resulting size of an element without modifying the layout of the element itself. It's primary use-case is for drawers (panels that slide in/out).

	<Panel Alignment="Center" Height="30" Color="#AFF">
		<StackPanel Alignment="TopLeft" Anchor="0%,100%" BoxSizing="Limit" LimitHeight="0%" ux:Name="theStack" Color="#AFA" ClipToBounds="true">
			<Text Value="One"/>
			<Text Value="Two"/>
			<Text Value="Three"/>
		</StackPanel>
		
		<WhileTrue ux:Name="showMenu">
			<Change theStack.LimitHeight="100%" Duration="0.5"/>
		</WhileTrue>
		
		<Clicked>
			<Toggle Target="showMenu"/>
		</Clicked>
	</Panel>

If you click on the box in the example a list of items will slide out from the top. This is done by starting with a `LimitHeight="0%"` and animating to `100%`. The percentage here refers to the calculated size of the element based on the `Standard` model. The height of the parent does not influence the children however (the available size in the limited dimensions is erased).

Notice the `ClipToBounds="true"`. Though the size is limited it doesn't prevent an element from being oversized, thus we clip to hide to oversized part.

> If you just want to do edge panels use an @Controls.EdgeNavigator instead, or consider a @Gestures.SwipeGesture to move it in/out. Panels at the edges don't need to be reduced in size since they can simply move out of the view area instead.


## FillAspect

The size of the element is calculated to meet the specified @Element.Aspect ratio. This is based on the available space in the parent element, but also considers any explicit `Width` or `Height` properties.

	<Grid BoxSizing="FillAspect" Aspect="2" ColumnCount="4" RowCount="2">

This creates a 4x2 grid that fills the available space but enforces the aspect of `2`, which causes it to be twice as wide as tall. This results in the cells being square.

Unlike the standard sizing model the content of the element, it's children, are not considered when calculating the size. It's strictly a calculation derived from the parent layout and the element's own layout properties.

You can use the `Element.AspectConstraint` to fine tune the sizing if your are relying on minimum and maximum sizes.
