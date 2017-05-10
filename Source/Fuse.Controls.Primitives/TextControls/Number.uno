using Uno;
using Uno.UX;

using Fuse.Elements;
using Fuse.Triggers;

namespace Fuse.Controls
{
	/** Deprecated, for backwards compatibility */
	public class Number : Panel, IValue<float>
	{
		TextControl _text;
		public Number()
		{
			Fuse.Diagnostics.Deprecated( "The Number control has been deprecated. Use a Text control instead and do the formatting inside JavaScript.", this );
			_text = new Text();
			Children.Add(_text);
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			UpdateValue();
		}
		
		string _format = "F0";
		public string Format
		{
			get { return _format; }
			set 
			{ 
				var newFormatString = "{0:" + value + "}";
				if (_format != value || _formatString != newFormatString)
				{
					_format = value;
					_formatString = newFormatString;
					UpdateValue();
				}
			}
		}

		string _formatString = "{0:F0}";
		public string FormatString
		{
			get { return _formatString; }
			set 
			{ 
				if (_formatString != value)
				{
					_formatString = value;
					UpdateValue();
				}
			}
		}
		
		float _value;		
		public float Value
		{
			get { return _value; }
			set 
			{ 
				if (_value != value)
				{
					_value = value;
					UpdateValue();
					OnValueChanged(value, this);
				}
			}
		}
		
		static Selector _valueName = "Value";
		public event ValueChangedHandler<float> ValueChanged;
		
		void OnValueChanged(float n, IPropertyListener origin)
		{
			OnPropertyChanged(_valueName);
			if (ValueChanged != null)
			{
				var args = new ValueChangedArgs<float>(n);
				ValueChanged(n, args);
			}
		}
		
		void UpdateValue()
		{
			try {
				_text.Value = String.Format(FormatString, Value);
			} catch (Exception e) {
				//TODO: restore, branch mixup
				//Fuse.Diagnostics.Exception( "Invalidat format: " + FormatString, e, this );
				throw e;
			} 
		}
	}
}
