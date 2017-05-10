using Uno;
using Uno.UX;

namespace Fuse.Triggers
{
	/** Active while the surrounding context contains text.

		Can be used, for instance, inside @TextInputs.

		## Example

		This example displays a warning text unless the user has entered some text into
a password field:

			<StackPanel>
				<TextInput IsPassword="True">
					<WhileContainsText>
						<Change warningText.Visibility="Hidden" />
					</WhileContainsText>
				</TextInput>
				<Text Color="Red" ux:Name="warningText">You must enter a password!</Text>
			</StackPanel>
	*/
	public class WhileContainsText : WhileTrigger
	{
		IValue<string> _source;
		public IValue<string> Source
		{
			get { return _source; }
			set { _source = value; }
		}
		
		IValue<string> _value;
		protected override void OnRooted()
		{
			base.OnRooted();
			if (Source != null)
				_value = Source;
			else
				_value = Parent as IValue<string>;
				
			if (_value != null)
			{
				_value.ValueChanged += OnValueChanged;
				SetActive(!string.IsNullOrEmpty(_value.Value));
			}
			else
			{
				Fuse.Diagnostics.UserError( "No TextInput or Source found for string", this );
			}
		}

		protected override void OnUnrooted()
		{
			if (_value != null)
			{
				_value.ValueChanged -= OnValueChanged;
				_value = null;
			}
			base.OnUnrooted();
		}

		void OnValueChanged(object sender, ValueChangedArgs<string> args)
		{
			SetActive(!string.IsNullOrEmpty(_value.Value));
		}
	}

	/** 
	    DEPRECATED: Use @WhileContainsText instead 
		
	*/
	public class ContainingText : WhileContainsText
	{
		public ContainingText()
		{
			Fuse.Diagnostics.Deprecated( "Use the trigger WhileContainsText instead", this );
		}
	}
	
}
