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
		protected override bool Compute(object left, object right, out object result)
		{
			result = Marshal.Add(left, right);
			return true;
		}

		public override string Symbol { get { return "+"; } } 
	}

	public sealed class Subtract: InfixOperator
	{
		[UXConstructor]
		public Subtract([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): base(left, right) {}
		protected override bool Compute(object left, object right, out object result)
		{
			result = Marshal.Subtract(left, right);
			return true;
		}

		public override string Symbol { get { return "-"; } } 
	}

	public sealed class Multiply: InfixOperator
	{
		[UXConstructor]
		public Multiply([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): base(left, right) {}
		protected override bool Compute(object left, object right, out object result)
		{
			result = Marshal.Multiply(left, right);
			return true;
		}

		public override string Symbol { get { return "*"; } } 
	}

	public sealed class Divide: InfixOperator
	{
		[UXConstructor]
		public Divide([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): base(left, right) {}
		protected override bool Compute(object left, object right, out object result)
		{
			result = Marshal.Divide(left, right);
			return true;
		}

		public override string Symbol { get { return "/"; } } 
	}

	public sealed class Conditional: TernaryOperator
	{
		[UXConstructor]
		public Conditional([UXParameter("Condition")] Expression condition, [UXParameter("TrueValue")] Expression trueValue, [UXParameter("FalseValue")] Expression falseValue)
			: base(condition, trueValue, falseValue) {}

		protected override bool Compute(object cond, object trueVal, object falseVal, out object result)
		{
			result = null;
			if (cond == null) return false;
			result = ((bool)Marshal.ToBool(cond)) ? trueVal : falseVal;
			return true;
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
		protected override bool Compute(object left, object right, out object result)
		{
			result = Marshal.LessThan(left, right);
			return true;
		}

		public override string Symbol { get { return "<"; } } 
	}

	public sealed class GreaterThan: InfixOperator
	{
		[UXConstructor]
		public GreaterThan([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): base(left, right) {}
		protected override bool Compute(object left, object right, out object result)
		{
			result = Marshal.GreaterThan(left, right);
			return true;
		}

		public override string Symbol { get { return ">"; } } 
	}

	public sealed class GreaterOrEqual: InfixOperator
	{
		[UXConstructor]
		public GreaterOrEqual([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): base(left, right) {}
		protected override bool Compute(object left, object right, out object result)
		{
			result = null;
			if (left == null || right == null) return false;
			result = (bool)Marshal.GreaterThan(left, right) || (bool)Marshal.EqualTo(left, right);
			return true;
		}

		public override string Symbol { get { return ">="; } } 
	}

	public sealed class LessOrEqual: InfixOperator
	{
		[UXConstructor]
		public LessOrEqual([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): base(left, right) {}
		protected override bool Compute(object left, object right, out object result)
		{
			result = null;
			if (left == null || right == null) return false;
			result = (bool)Marshal.LessThan(left, right) || (bool)Marshal.EqualTo(left, right);
			return true;
		}

		public override string Symbol { get { return "<="; } } 
	}

	public sealed class Equal: InfixOperator
	{
		[UXConstructor]
		public Equal([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): base(left, right) {}
		protected override bool Compute(object left, object right, out object result)
		{
			result = Marshal.EqualTo(left, right);
			return true;
		}

		public override string Symbol { get { return "=="; } } 
	}

	public sealed class NotEqual: InfixOperator
	{
		[UXConstructor]
		public NotEqual([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): base(left, right) {}
		protected override bool Compute(object left, object right, out object result)
		{
			result = null;
			if (left == null || right == null) return false;
			result = !(bool)Marshal.EqualTo(left, right);
			return true;
		}

		public override string Symbol { get { return "!="; } } 
	}

	public sealed class LogicalAnd: InfixOperator
	{
		[UXConstructor]
		public LogicalAnd([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): base(left, right) {}
		protected override bool Compute(object left, object right, out object result)
		{
			result = null;
			if (left == null || right == null) return false;
			result = (bool)Marshal.ToBool(left) && (bool)Marshal.ToBool(right);
			return true;
		}

		public override string Symbol { get { return "&&"; } } 
	}

	public sealed class LogicalOr: InfixOperator
	{
		[UXConstructor]
		public LogicalOr([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): base(left, right) {}
		protected override bool Compute(object left, object right, out object result)
		{
			result = null;
			if (left == null || right == null) return false;
			result = (bool)Marshal.ToBool(left) || (bool)Marshal.ToBool(right);
			return true;
		}

		public override string Symbol { get { return "||"; } } 
	}

}