using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Reactive
{
	public abstract class InfixOperator: BinaryOperator
	{
		protected InfixOperator(Expression left, Expression right): base(left, right) {}

		public abstract string Symbol { get; }

		public override string ToString()
		{
			return "(" + Left + " " + Symbol + " " + Right + ")";
		}
	}

	public sealed class Add: InfixOperator
	{
		[UXConstructor]
		public Add([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): base(left, right) {}
		protected override object Compute(object left, object right)
		{
			return Marshal.Add(left, right);
		}

		public override string Symbol { get { return "+"; } } 
	}

	public sealed class Subtract: InfixOperator
	{
		[UXConstructor]
		public Subtract([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): base(left, right) {}
		protected override object Compute(object left, object right)
		{
			return Marshal.Subtract(left, right);
		}

		public override string Symbol { get { return "-"; } } 
	}

	public sealed class Multiply: InfixOperator
	{
		[UXConstructor]
		public Multiply([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): base(left, right) {}
		protected override object Compute(object left, object right)
		{
			return Marshal.Multiply(left, right);
		}

		public override string Symbol { get { return "*"; } } 
	}

	public sealed class Divide: InfixOperator
	{
		[UXConstructor]
		public Divide([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): base(left, right) {}
		protected override object Compute(object left, object right)
		{
			return Marshal.Divide(left, right);
		}

		public override string Symbol { get { return "/"; } } 
	}

	/*public sealed class NullCoalesce: InfixOperator
	{
		[UXConstructor]
		public NullCoalesce([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): base(left, right) {}

		protected override bool IsLeftOptional { get { return true; } }

		protected override object Compute(object left, object right)
		{
			if (left != null) return left;
			else return right;
		}

		public override string Symbol { get { return "??"; } } 
	}*/

	public sealed class Conditional: TernaryOperator
	{
		[UXConstructor]
		public Conditional([UXParameter("Condition")] Expression condition, [UXParameter("TrueValue")] Expression trueValue, [UXParameter("FalseValue")] Expression falseValue)
			: base(condition, trueValue, falseValue) {}

		protected override object Compute(object cond, object trueVal, object falseVal)
		{
			if (cond == null) return null;
			if ((bool)Marshal.ToBool(cond)) return trueVal;
			return falseVal;
		}

		protected override bool IsThirdOptional { get { return true; } }

		public override string ToString() 
		{
			return "(" + First + " ? " + Second + " : " + Third + ")";
		}
	}

	public sealed class LessThan: InfixOperator
	{
		[UXConstructor]
		public LessThan([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): base(left, right) {}
		protected override object Compute(object left, object right)
		{
			return Marshal.LessThan(left, right);
		}

		public override string Symbol { get { return "<"; } } 
	}

	public sealed class GreaterThan: InfixOperator
	{
		[UXConstructor]
		public GreaterThan([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): base(left, right) {}
		protected override object Compute(object left, object right)
		{
			return Marshal.GreaterThan(left, right);
		}

		public override string Symbol { get { return ">"; } } 
	}

	public sealed class GreaterOrEqual: InfixOperator
	{
		[UXConstructor]
		public GreaterOrEqual([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): base(left, right) {}
		protected override object Compute(object left, object right)
		{
			if (left == null || right == null) return null;
			return (bool)Marshal.GreaterThan(left, right) || (bool)Marshal.EqualTo(left, right);
		}

		public override string Symbol { get { return ">="; } } 
	}

	public sealed class LessOrEqual: InfixOperator
	{
		[UXConstructor]
		public LessOrEqual([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): base(left, right) {}
		protected override object Compute(object left, object right)
		{
			if (left == null || right == null) return null;
			return (bool)Marshal.LessThan(left, right) || (bool)Marshal.EqualTo(left, right);
		}

		public override string Symbol { get { return "<="; } } 
	}

	public sealed class Equal: InfixOperator
	{
		[UXConstructor]
		public Equal([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): base(left, right) {}
		protected override object Compute(object left, object right)
		{
			return Marshal.EqualTo(left, right);
		}

		public override string Symbol { get { return "=="; } } 
	}

	public sealed class NotEqual: InfixOperator
	{
		[UXConstructor]
		public NotEqual([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): base(left, right) {}
		protected override object Compute(object left, object right)
		{
			if (left == null || right == null) return null;
			return !(bool)Marshal.EqualTo(left, right);
		}

		public override string Symbol { get { return "!="; } } 
	}

	public sealed class LogicalAnd: InfixOperator
	{
		[UXConstructor]
		public LogicalAnd([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): base(left, right) {}
		protected override object Compute(object left, object right)
		{
			if (left == null || right == null) return null;
			return (bool)Marshal.ToBool(left) && (bool)Marshal.ToBool(right);
		}

		public override string Symbol { get { return "&&"; } } 
	}

	public sealed class LogicalOr: InfixOperator
	{
		[UXConstructor]
		public LogicalOr([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): base(left, right) {}
		protected override object Compute(object left, object right)
		{
			if (left == null || right == null) return null;
			return (bool)Marshal.ToBool(left) || (bool)Marshal.ToBool(right);
		}

		public override string Symbol { get { return "||"; } } 
	}

}