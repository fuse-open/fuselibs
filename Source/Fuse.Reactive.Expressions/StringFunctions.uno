using Uno.UX;

namespace Fuse.Reactive
{
	[UXFunction("toUpper")]
	public sealed class ToUpper: UnaryOperator
	{
		[UXConstructor]
		public ToUpper([UXParameter("Value")] Expression value): base(value) {}
		protected override object Compute(object s)
		{
			return s.ToString().ToUpper();
		}

		public override string ToString()
		{
			return "toUpper(" + Operand + ")";
		}
	}

	[UXFunction("toLower")]
	public sealed class ToLower: UnaryOperator
	{
		[UXConstructor]
		public ToLower([UXParameter("Value")] Expression value): base(value) {}
		protected override object Compute(object s)
		{
			return s.ToString().ToLower();
		}

		public override string ToString()
		{
			return "toLower(" + Operand + ")";
		}
	}
}