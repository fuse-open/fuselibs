using Uno.UX;

namespace Fuse.Reactive
{
	[UXFunction("min")]
	public sealed class Min: BinaryOperator
	{
		[UXConstructor]
		public Min([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): base(left, right) {}
		protected override object Compute(object left, object right)
		{
			return Marshal.Min(left, right);
		}

		public override string ToString()
		{
			return "min(" + Left + ", " + Right + ")";
		}
	}

	[UXFunction("max")]
	public sealed class Max: BinaryOperator
	{
		[UXConstructor]
		public Max([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): base(left, right) {}
		protected override object Compute(object left, object right)
		{
			return Marshal.Max(left, right);
		}

		public override string ToString()
		{
			return "max(" + Left + ", " + Right + ")";
		}
	}
}