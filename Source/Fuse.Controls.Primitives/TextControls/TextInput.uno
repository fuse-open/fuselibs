using Uno.UX;
using Fuse.Layouts;
using Fuse.Elements;

namespace Fuse.Controls
{
	/** Single-line text input control.
	
		`TextInput` is what you typically use or subclass when making input fields that only require a single line, like usernames, passwords, numbers, email, search fields, etc.
		It has no appearance by default, which means it will be invisible until you give it a look or a text value.
		
		> If you want a text input control with a default appearance, see @TextBox.
		> If you want to accept multiple lines of text, use @TextView.

		## Examples

		This example shows a basic TextInput with some style and a button to clear its contents.

			<Panel>
				<Button Alignment="CenterRight" Text="Clear" Margin="5">
					<Clicked>
						<Set text.Value="" />
					</Clicked>
				</Button>
				<TextInput ux:Name="text" PlaceholderText="Text field" PlaceholderColor="#ccc" Height="50" Padding="5" >
					<Rectangle Layer="Background">
						<Stroke Width="2" Brush="#BBB" />
					</Rectangle>
				</TextInput>
			</Panel>
			
		The following example illustrates how you can subclass TextInput to achieve a consistent look throughout your app.
		
			<!-- Subclassing TextInput -->
			<TextInput ux:Class="MyTextInput" FontSize="20" PlaceholderColor="#ccc" Padding="5">
				<Rectangle Layer="Background" CornerRadius="3">
					<Stroke Width="1" Color="#ccc" />
					<SolidColor Color="White" />
				</Rectangle>
			</TextInput>
			
			<!-- Example usage -->
			<StackPanel Margin="10" ItemSpacing="10">
				<MyTextInput PlaceholderText="Username" />
				<MyTextInput PlaceholderText="Password" IsPassword="true" />
				<MyTextInput PlaceholderText="Repeat password" IsPassword="true" />
				<MyTextInput />
			</StackPanel>
			
			
		This example shows how you can configure the layout and behavior of the on-screen keyboard when the TextInput is in focus using the @InputHint, @AutoCorrectHint, @AutoCapitalizationHint and @ActionStyle properties.
		
			<TextInput PlaceholderText="Search..." ActionStyle="Search" AutoCapitalizationHint="None" />
			<TextInput PlaceholderText="Email" InputHint="Email" ActionStyle="Send" AutoCorrectHint="Disabled" AutoCapitalizationHint="None" />
			<TextInput PlaceholderText="http://" InputHint="URL" ActionStyle="Go" AutoCorrectHint="Disabled" AutoCapitalizationHint="None" />
			<TextInput PlaceholderText="+47 123 456 789" InputHint="Phone" />
			<TextInput PlaceholderText="1234" InputHint="Number" />
			<TextInput PlaceholderText="1.234" InputHint="Decimal" />
			<TextInput PlaceholderText="1" InputHint="Integer" />

		A common use-case is to have the TextInput raise an event when the user presses the return/search key on their virtual/physical keyboard. 
		The following example demonstrates using `ActionTriggered` to get an event when this happens:

			<StackPanel>
				<JavaScript>
					var Observable = require("FuseJS/Observable");

					var searchStr = Observable("Please enter a query...");
					var entryStr = Observable("");
					
					function onSearch(args) {
						searchStr.value = "You entered: " + entryStr.value;
					}

					module.exports = {
						searchStr: searchStr,
						onSearch: onSearch,
						entryStr: entryStr
					};
				</JavaScript>
				<Text FontSize="20">Search</Text>
				<TextInput Value="{entryStr}" PlaceholderText="Enter your query...." ActionTriggered="{onSearch}" />
				<Text FontSize="20" Value="{searchStr}" />
			</StackPanel>

		In some cases, it might be undesirable for the virtual keyboard to disappear when a certain other ux element is pressed. 
		This can be done by passing a parent container to the `Focus.Delegate` property, causing the focus state to be delegated to the delegate target:

			<DockPanel ux:Name="dockpanel" IsFocusable="true" Color="#fff">
				<TextInput Focus.Delegate="dockpanel" />
				<Panel Dock="Right">
					<Text Value="SEND" Alignment="Center" Margin="4,0" Color="#fff" />
					<Rectangle CornerRadius="4" Color="#000" />
				</Panel>
			</DockPanel>
		
	*/
	public class TextInput: TextInputControl, ITextEditControl
	{
		public TextInput() : base(Create())
		{
			Editor.Alignment = Alignment.VerticalCenter;
		}

		static TextEdit Create()
		{
			if defined(Mobile) return new MobileTextEdit(false);
			else if defined(USE_HARFBUZZ) return new FuseTextEdit(false);
			else return new DesktopTextEdit(false);
		}

		/** Set to `true` to display dots instead of the actual text value. */
		public bool IsPassword { get { return Editor.IsPassword; } set { Editor.IsPassword = value; } }

		/** Visual alignment of the underlying text editor. */
		public Alignment EditorAlignment { get { return Editor.Alignment; } set { Editor.Alignment = value; } }
		
		/** Text to show when the `TextInputControl` does not have a value
		*/
		public string PlaceholderText { get { return Editor.PlaceholderText; } set { Editor.PlaceholderText = value; } }

		/** Color of the `PlaceholderText`
		*/
		public float4 PlaceholderColor { get { return Editor.PlaceholderColor; } set { Editor.PlaceholderColor = value; } }

		/** 
		 * Fires when the user presses the return/search key on their virtual/physical keyboard.
		 */
		public event TextInputActionHandler	ActionTriggered
		{
			add { Editor.ActionTriggered += value; }
			remove { Editor.ActionTriggered -= value; }
		}
		
		/** Specifies what the returnkey should mean. For exmaple:
			`ActionStyle="Send"` will change the return key to a send icon if the platform supports it.
			`ActionStyle="Next"` will make the return key focus the next `TextInputControl` if any. Typically
			used in forms.
		*/
		public TextInputActionStyle ActionStyle { get { return Editor.ActionStyle; } set { Editor.ActionStyle = value; } }
		
	}

	/**	Multi-line text editor.

		TextView provides features for editing and viewing large amounts of text.

		## Example

			<TextView ux:Class="TextViewer" TextWrapping="Wrap" Padding="4" Margin="4" TextColor="#000" CaretColor="#000">
					Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

				<Rectangle Layer="Background" CornerRadius="4">
					<Stroke Color="#000" />
				</Rectangle>
				
			</TextView>

	*/
	public class TextView: TextInputControl
	{
		public TextView() : base(Create())
		{
		}

		static TextEdit Create()
		{
			if defined(Mobile) return new MobileTextEdit(true);
			else if defined(USE_HARFBUZZ) return new FuseTextEdit(true);
			else return new DesktopTextEdit(true);
		}
	}
}
