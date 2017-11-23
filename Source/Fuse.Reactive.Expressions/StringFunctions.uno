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
			if (s != null)
				return s.ToString().ToUpper();

			return null;
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
			if (s != null)
				return s.ToString().ToLower();

			return null;
		}

		public override string ToString()
		{
			return "toLower(" + Operand + ")";
		}
	}
}
