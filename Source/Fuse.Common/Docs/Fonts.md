
# Working with fonts

You can specify a `Font` on @TextControls such as @Text, @TextInput and @TextEdit.

## Specifying global font alias

A font can be declared and given a global alias for your project like this:

	<Font File="arial.ttf" ux:Global="Regular" />

And then used like this:

	<Text Font="Regular" />

## Creating text classes 

You can specify custom `Text` classes to combine font face, size and color information:

	<Text ux:Class="Header1" Font="Regular" FontSize="30" Color="#333" />

And then use it like this:

	<Header1>Welcome!</Header>

## Specifying font files inline

Fonts can be specified inline on a text element like this:

	<Text>
		<Font File="arial.ttf" />
	</Text>

## Using system fonts

Access to system fonts is currently not supported, but this feature planned.

When using a native @Theme, if no font is specified on an element, it will use the default OS font.