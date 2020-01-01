using Uno;
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

	[UXFunction("trim")]
	public sealed class Trim: UnaryOperator
	{
		[UXConstructor]
		public Trim([UXParameter("Value")] Expression value): base(value, "trim") {}
		protected override bool TryCompute(object s, out object result)
		{
			result = null;
			if (s == null) return false;
			result = s.ToString().Trim();
			return true;
		}
	}

	[UXFunction("indexOf")]
	public sealed class IndexOf: BinaryOperator
	{
		[UXConstructor]
		public IndexOf([UXParameter("Value")] Expression value, [UXParameter("String")] Expression str): base(value, str, "trim") {}
		protected override bool TryCompute(object s, object left, out object result)
		{
			result = null;
			if (s == null || left == null) return false;
			try
			{
				result = s.ToString().IndexOf(left.ToString());
			}
			catch (ArgumentOutOfRangeException exception)
			{
				return false;
			}
			return true;
		}
	}

	[UXFunction("substring")]
	public sealed class Substring: TernaryOperator
	{
		[UXConstructor]
		public Substring([UXParameter("Value")] Expression value, [UXParameter("Start")] Expression start, [UXParameter("Length")] Expression length): base(value, start, length) {}

		protected override bool TryCompute(object s, object left, object right, out object result)
		{
			result = null;
			int start = 0;
			int length = 0;
			if (!Marshal.TryToType<int>(left, out start) ||
				!Marshal.TryToType<int>(right, out length))
				return false;
			if (s == null) return false;
			try
			{
				result = s.ToString().Substring(start, length);
			}
			catch (ArgumentOutOfRangeException exception)
			{
				return false;
			}
			return true;
		}
	}

	[UXFunction("replace")]
	public sealed class Replace: TernaryOperator
	{
		[UXConstructor]
		public Replace([UXParameter("Value")] Expression value, [UXParameter("OldValue")] Expression oldValue, [UXParameter("NewValue")] Expression newValue): base(value, oldValue, newValue) {}

		protected override bool TryCompute(object s, object oldValue, object newValue, out object result)
		{
			result = null;
			if (s == null || oldValue == null || newValue == null) return false;
			result = s.ToString().Replace(oldValue.ToString(), newValue.ToString());
			return true;
		}
	}

	[UXFunction("insert")]
	public sealed class Insert: TernaryOperator
	{
		[UXConstructor]
		public Insert([UXParameter("Value")] Expression value, [UXParameter("Position")] Expression pos, [UXParameter("String")] Expression str): base(value, pos, str) {}

		protected override bool TryCompute(object s, object left, object right, out object result)
		{
			result = null;
			int pos = 0;
			if (!Marshal.TryToType<int>(left, out pos)) return false;
			if (s == null || right == null) return false;
			try
			{
				result = s.ToString().Insert(pos, right.ToString());
			}
			catch (Exception exception)
			{
				return false;
			}
			return true;
		}
	}

	[UXFunction("split")]
	public sealed class Split: BinaryOperator
	{
		[UXConstructor]
		public Split([UXParameter("Value")] Expression value, [UXParameter("Token")] Expression token): base(value, token, "split") {}

		protected override bool TryCompute(object s, object token, out object result)
		{
			result = null;
			if (s == null || token == null) return false;
			try
			{
				result = s.ToString().Split(token.ToString().ToCharArray());
			}
			catch (Exception exception)
			{
				return false;
			}
			return true;
		}
	}

	[UXFunction("startsWith")]
	public sealed class StartsWith: BinaryOperator
	{
		[UXConstructor]
		public StartsWith([UXParameter("Value")] Expression value, [UXParameter("String")] Expression str): base(value, str, "startsWith") {}

		protected override bool TryCompute(object s, object str, out object result)
		{
			result = null;
			if (s == null || str == null) return false;
			result = s.ToString().StartsWith(str.ToString());
			return true;
		}
	}

	[UXFunction("endsWith")]
	public sealed class EndsWith: BinaryOperator
	{
		[UXConstructor]
		public EndsWith([UXParameter("Value")] Expression value, [UXParameter("String")] Expression str): base(value, str, "endsWith") {}

		protected override bool TryCompute(object s, object str, out object result)
		{
			result = null;
			if (s == null || str == null) return false;
			result = s.ToString().EndsWith(str.ToString());
			return true;
		}
	}
}
