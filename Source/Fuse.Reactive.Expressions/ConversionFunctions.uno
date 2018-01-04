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
	/** Forces conversion to a Size or Size2 depending on input size.
	
		This is useful when using operators that may not be able to infer the desired types. For example:
		
			<JavaScript>
				exports.jsArray = [0.2, 0.4]
			</JavaScript>
			<Panel Offset="size({jsArray}) * 100%"/>
			
		This function follows the conversion rules as though the operand was being converted directly to a `Size` or `Size2` property type. If the input is a `float2`, array, or already a Size2, then it will be converted to a `Size2`, otherwise a `Size` type.
	*/
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

			Size2 r;
			int rc;
			if (!Marshal.TryToSize2(operand, out r, out rc))
				return false;
				
			if (rc == 1)
				result = r.X;
			else
				result = r;
			return true;
		}
	}
}
