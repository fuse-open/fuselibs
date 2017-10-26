using Uno;

using Fuse;

namespace FuseTest
{
	public class Data : Behavior
	{
		//only one backing value to prevent tests from seeing different values
		object _value;
		
		public object Value 
		{ 
			get { return _value; }
			set { SetValue(value); }
		}
		
		void SetValue( object value )
		{ 
			_value = value; 
			if (IsRootingCompleted)
			{
				OnPropertyChanged( "Value" );
				OnPropertyChanged( "FloatValue" );
				OnPropertyChanged( "StringValue" );
			}
		}
		
		public float FloatValue
		{
			get { return (float)_value; }
			set { _value = value; }
		}
		
		public string StringValue 
		{ 
			get { return (string)_value; }
			set { _value = value; }
		}
	}
}
