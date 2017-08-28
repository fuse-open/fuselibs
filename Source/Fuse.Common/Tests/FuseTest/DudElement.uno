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
		public float Value { get; set; }
		
		public string StringValue { get; set; }

		public IArray ArrayValue { get; set; }
		
		public object ObjectValue { get; set; }
		
		public IExpression Expression { get; set; }
		
		public IObject IObjectValue { get; set; }
		
		public object UseValue 
		{
			get
			{
				if (StringValue != null)
					return StringValue;
				if (ArrayValue != null)
					return ArrayValue;
				if (ObjectValue != null)
					return ObjectValue;
				if (IObjectValue != null)
					return IObjectValue;
				return Value;
			}
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
