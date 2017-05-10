using Uno;
using Uno.UX;

using Fuse.Input;

namespace Fuse.Triggers.Actions
{
	/**
		Gives focus to its containing @Element when activated.

		It also accepts a `Target` property, which specifies which element to give focus to.

		# Example
		In the following example, focus is given to a `TextInput` when a button is clicked.

			<StackPanel>
				<TextInput ux:Name="input" Height="50" Value="Filler text"/>
				<Button Text="Button">
					<Clicked>
						<GiveFocus Target="input" />
					</Clicked>
				</Button>
			</StackPanel>
	*/
	public class GiveFocus: TriggerAction
	{
		public Visual Target { get; set; }

		protected override void Perform(Node target)
		{
			Focus.GiveTo(Target ?? target as Visual);
		}

		[UXGlobalResource("GiveFocus")] public static readonly TriggerAction Singleton = new GiveFocus();
	}
	
	/**
		Releases focus from the currently focused Element when activated.

		# Example
		In this example, a `TextInput` will release its focus when the Enter key on the keyboard is pressed.

			<TextInput ux:Name="input" Height="50" Value="Filler text">
				<TextInputActionTriggered>
					<ReleaseFocus />
				</TextInputActionTriggered>
			</TextInput>
	*/
	public class ReleaseFocus : TriggerAction
	{
		protected override void Perform(Node target)
		{
			Focus.GiveTo(null);
		}
	}
}
