namespace Fuse.Controls
{
	/** Displays a button
	
		The default button in Fuse. Its appearance is transparent with blue text. 
		To change the look or to create a semantically specific button, create a Subclass of this Class. 
		Please note that when used inside a @NativeViewHost, this button will have the platform native appearance 
		which might need additional styling to make it visible. For example, on iOS the default native appearance of a 
		button is blue text on white.

		## Examples

		By default, `Button` is drawn as blue text over a transparent background.
		
			<Button Text="Click me" />
		
		However, Button can also be used to render the *platform native* button control whenever possible.
		This is done by wrapping the Button in a @NativeViewHost, as shown below.

			<NativeViewHost>
				<Button Text="Native button" />
			</NativeViewHost>

		However, we usually want a button with our own look and feel.
		In this case, it is recommended to subclass @Panel rather than Button.
		Since you can attach a `Clicked` handler to any element, using a @Panel as the base class offers a
		great deal of flexibility, while removing a lot of the unnecessary complexity of the actual Button class.
		
		Below is an example of creating your own button control with @Panel:
		
			<Panel ux:Class="MyButton" HitTestMode="LocalBounds" Margin="4" Color="#25a">
				<string ux:Property="Text" />
				<Text Value="{ReadProperty Text}" Color="#fff" Alignment="Center" Margin="30,15" />

				<WhilePressed>
					<Change this.Color="#138" Duration="0.05" DurationBack=".2" />
				</WhilePressed>
			</Panel>
			
			<MyButton Text="Click me" />
		
		However, if you want a *platform native button* that falls back to a custom look on non-mobile devices,
		you have to subclass `Button`.

			<Button ux:Class="MyNativeButtonWithFallback" Margin="2">
				<Panel ux:Template="GraphicsAppearance" HitTestMode="LocalBounds">
					<Text Value="{ReadProperty Text}" Color="#fff" Alignment="Center" TextAlignment="Center" Margin="10" />
					<Rectangle CornerRadius="4" Layer="Background" Color="#25a" />
				</Panel>
			</Button>
		
		When placed in a @NativeViewHost, the Button will attempt to initialize a *native* button control.
		If this is not possible (e.g. if it's running on desktop), it will fall back to the template specified
		by `ux:Template="GraphicsAppearance"`.`
		
			<NativeViewHost>
				<!-- Will be native if possible -->
				<MyNativeButtonWithFallback Text="Some button" />
			</NativeViewHost>
		
		If we *don't* place the Button inside a @NativeViewHost,
		the `GraphicsAppearance` template will always be used to draw the button.

			<MyNativeButtonWithFallback />

	*/
	public partial class Button { }

}