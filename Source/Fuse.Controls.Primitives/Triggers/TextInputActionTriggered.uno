using Uno;

using Fuse.Controls;

namespace Fuse.Triggers
{
	/** Trigger for input action

		Triggers when the returnkey on the keyboard is clicked.

		## Example

			<TextInput PlaceholderText="Example">
				<TextInputActionTriggered>
					<DebugAction Message="TextInputActionTriggered" />
				</TextInputActionTriggered>
			</TextInput>

	*/
	public class TextInputActionTriggered : Trigger
	{
		TextInputActionType _type = TextInputActionType.Primary;
		/**
			Specifies what ActionType to trigger on
		*/
		public TextInputActionType Type
		{
			get { return _type; }
			set { _type = value; }
		}

		ITextEditControl _textEdit;
		protected override void OnRooted()
		{
			base.OnRooted();
			_textEdit = Parent as ITextEditControl;
			if (_textEdit == null)
			{
				Fuse.Diagnostics.UserError("TextInputActionTriggered must be a child of an ITextEdit", this);
			}
			else
			{
				_textEdit.ActionTriggered += OnActionTriggered;
			}
		}

		protected override void OnUnrooted()
		{
			if (_textEdit != null)
			{
				_textEdit.ActionTriggered -= OnActionTriggered;
				_textEdit = null;
			}
			base.OnUnrooted();
		}

		void OnActionTriggered(object s, TextInputActionArgs args)
		{
			if (args.Type != Type)
				return;
			Pulse();
		}
	}
}
