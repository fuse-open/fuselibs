namespace Alive
{
	/**
		Alive comes with a set of icons, exposed via the Icon component.
	
		@topic Alive Icons

		The icons come bundled in a font file.
		Thus, the `Icon` component is simply a @Text with the `Alive.IconFont` for its Font.

		Icons are specified as hexadecimal escape codes to the `Value` property, referring to their unicode code point.

		```
		<Alive.Icon Value="&#xEB96;" />
		```

		The width and height of an icon is determined by the `Size` property..
		
		```
		<Alive.Icon Value="&#xEA3A;" Size="48" />
		```
		
		## All icons
		
		@include Docs/IconTable.md


	*/
	public partial class Icon {}
}
