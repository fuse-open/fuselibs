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
}
