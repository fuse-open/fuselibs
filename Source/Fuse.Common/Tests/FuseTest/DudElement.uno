using Uno;

using Fuse;
using Fuse.Controls;
using Fuse.Elements;
using Fuse.Reactive;

namespace FuseTest
{
	/**
		Can contain a value but doesn't update layout in response to any changes, nor does it have any natural size, nor does it draw anything.
	*/
	public class DudElement : Element
	{
		//only one backing value to prevent tests from seeing different values
		object _value;
		
		public float Value 
		{ 
			get { return (float)_value; }
			set { _value = value; }
		}
		
		public string StringValue 
		{ 
			get { return (string)_value; }
			set { _value = value; }
		}

		public IArray ArrayValue
		{ 
			get { return (IArray)_value; }
			set { _value = value; }
		}
		
		public object ObjectValue
		{ 
			get { return _value; }
			set { _value = value; }
		}
		
		public IExpression Expression
		{ 
			get { return (IExpression)_value; }
			set { _value = value; }
		}
		
		public IObject IObjectValue
		{ 
			get { return (IObject)_value; }
			set { _value = value; }
		}
		
		public bool BoolValue
		{
			get { return (bool)_value; }
			set { _value = value; }
		}
		
		public object UseValue 
		{
			get { return _value; }
		}
		
		protected override float2 GetContentSize( LayoutParams lp )
		{
			return float2(0);
		}
		
		protected override void OnDraw(Fuse.DrawContext dc) { }
		
		public override string ToString()
		{
			return "Dud@" + GetHashCode() + "=" + UseValue;
		}
	}
}
