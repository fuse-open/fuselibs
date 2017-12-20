using Uno.UX;

namespace Fuse.Reactive
{
	[UXFunction("toUpper")]
	public sealed class ToUpper: UnaryOperator
	{
		[UXConstructor]
		public ToUpper([UXParameter("Value")] Expression value): base(value,"toUpper") {}
		protected override bool TryCompute(object s, out object result)
		{
			result = null;
			if (s == null) return false;
			result = s.ToString().ToUpper();
			return true;
		}

	}

	[UXFunction("toLower")]
	public sealed class ToLower: UnaryOperator
	{
		[UXConstructor]
		public ToLower([UXParameter("Value")] Expression value): base(value, "toLower") {}
		protected override bool TryCompute(object s, out object result)
		{
			result = null;
			if (s == null) return false;
			result = s.ToString().ToLower();
			return true;
		}
	}
}
