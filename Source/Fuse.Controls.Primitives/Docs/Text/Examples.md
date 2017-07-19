# Examples 

## Text properties

```
<Text Color="#999">Left</Text>
<Text TextAlignment="Center">Center</Text>
<Text FontSize="24" TextAlignment="Right">Right</Text>
<Text LineSpacing="10">
Multiple
Lines
</Text>
```

In this example, the first text element will be left aligned as this is the default, and have its color set to a medium light grey. The second text will be center aligned. The third will be right aligned and have a larger font. The fourth will span two lines with 10 points of space inbetween.

## Custom text-components

	<App>
		<Font File="Roboto-Medium.ttf" ux:Global="Medium" />
		<Font File="Roboto-Light.ttf" ux:Global="Light" />

		<Text ux:Class="Light" Font="Light" />
		<Text ux:Class="Medium" Font="Medium" TextWrapping="Wrap" />
		<Text ux:Class="Warning" 
			Font="Medium" 
			FontSize="42"
			TextAlignment="Center"
			Color="#f00" />
			
		<StackPanel>
			<Light>Just some text</Light>
			<Warning>The robots are coming!</Warning>
			<Medium>This is just some medium text, but it will happily wrap when the edges of the screen is reached.</Medium>
		</StackPanel>
	</App>

In this example we load two fonts and create three different semantic classes, `Light`, `Medium` and `Warning`, combining some of the available `Text` properties. In this example, the fonts are located in the same directory as the relevant UX file. 