using Uno;
using Uno.UX;

namespace Fuse.Reactive
{
	[UXFunction("float")]
	/** Forces a conversion to floating point. This supports any 1-4 component float vector. */
	public sealed class ToFloat : UnaryFloatOperator
	{
		[UXConstructor]
		public ToFloat([UXParameter("Operand")] Expression operand)
			: base(operand, "float", Op) {}
			
		internal static double Op(double v)
		{
			return v;
		}
	}
	
	[UXFunction("string")]
	/** Forces conversion to a string value. */
	public sealed class ToString : UnaryOperator
	{
		[UXConstructor]
		public ToString([UXParameter("Operand")] Expression operand)
			: base(operand, "string") { }
			
		protected override bool TryCompute(object operand, out object result)
		{
			result = null;
			if (operand == null)
				return false;
				
			result = operand.ToString();
			return true;
		}
	}
	
	[UXFunction("size")]
	/** Forces conversion to a Size or Size2 depending on input size. */
	public sealed class ToSize : UnaryOperator
	{
		[UXConstructor]
		public ToSize([UXParameter("Operand")] Expression operand)
			: base(operand, "size") { }
			
		protected override bool TryCompute(object operand, out object result)
		{
			result = null;
			if (operand == null)
				return false;
				
			return false;
		}
	}
}
