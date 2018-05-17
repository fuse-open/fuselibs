using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Reactive
{
	public abstract class InfixOperator: BinaryOperator
	{
		/** @deprecated Use the constructor that takes a name, as flags */
		[Obsolete]
		protected InfixOperator(Expression left, Expression right): base(left, right) {}
		
		protected InfixOperator(Expression left, Expression right, string symbol, Flags flags = Flags.None) :
			base(left, right, symbol, flags) 
		{ }

		/** @deprecated Provide a name to the constructor instead. */
		public virtual string Symbol { get { return ""; } }

		public override string ToString()
		{
			return "(" + Left + " " + (Name ?? Symbol) + " " + Right + ")";
		}
	}

	public sealed class Concat : InfixOperator
	{
		[UXConstructor]
		public Concat([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right) : 
			base(left, right, "++") {}
		protected override bool TryCompute(object left, object right, out object result)
		{
			return TryComputeImpl(left, right, out result);
		}
		
		static internal bool TryComputeImpl(object left, object right, out object result)
		{
			result = null;
			string a = null, b = null;
			if (!Marshal.TryToType<string>(left, out a) ||
				!Marshal.TryToType<string>(right, out b))
				return false;
				
			result = a + b;
			return true;
		}
	}
	
	public sealed class Add: InfixOperator
	{
		[UXConstructor]
		public Add([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right) : 
			base(left, right, "+") {}
		protected override bool TryCompute(object left, object right, out object result)
		{
			//Workaround for UX emitting `Add` instead of `Concat`
			//https://github.com/fuse-open/fuselibs/issues/897
			if (left is string || right is string)
				return Concat.TryComputeImpl(left, right, out result);
				
			return Marshal.TryAdd(left, right, out result);
		}
	}

	public sealed class Subtract: InfixOperator
	{
		[UXConstructor]
		public Subtract([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): 
			base(left, right, "-") {}
		protected override bool TryCompute(object left, object right, out object result)
		{
			return Marshal.TrySubtract(left, right, out result);
		}
	}

	public sealed class Multiply: InfixOperator
	{
		[UXConstructor]
		public Multiply([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): 
			base(left, right, "*") {}
		protected override bool TryCompute(object left, object right, out object result)
		{
			return Marshal.TryMultiply(left, right, out result);
		}
	}

	public sealed class Divide: InfixOperator
	{
		[UXConstructor]
		public Divide([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): 
			base(left, right,"/") {}
		protected override bool TryCompute(object left, object right, out object result)
		{
			return Marshal.TryDivide(left, right, out result);
		}
	}

	public sealed class Conditional: TernaryOperator
	{
		[UXConstructor]
		public Conditional([UXParameter("Condition")] Expression condition, [UXParameter("TrueValue")] Expression trueValue, [UXParameter("FalseValue")] Expression falseValue)
			: base(condition, trueValue, falseValue, Flags.Optional2) {}

		protected override bool TryCompute(object cond, object trueVal, object falseVal, out object result)
		{
			result = null;
			if (cond == null) return false;
			result = ((bool)Marshal.ToBool(cond)) ? trueVal : falseVal;
			return true;
		}

		public override string ToString() 
		{
			return "(" + First + " ? " + Second + " : " + Third + ")";
		}
	}

	public sealed class LessThan: InfixOperator
	{
		[UXConstructor]
		public LessThan([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): 
			base(left, right,"<") {}
		protected override bool TryCompute(object left, object right, out object result)
		{
			bool v = false;
			var r = Marshal.TryLessThan(left, right, out v);
			result = v;
			return r;
		}
	}

	public sealed class GreaterThan: InfixOperator
	{
		[UXConstructor]
		public GreaterThan([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right):
			base(left, right, ">") {}
		protected override bool TryCompute(object left, object right, out object result)
		{
			bool v = false;
			var r = Marshal.TryGreaterThan(left, right, out v);
			result = v;
			return r;
		}
	}

	public sealed class GreaterOrEqual: InfixOperator
	{
		[UXConstructor]
		public GreaterOrEqual([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right)
			: base(left, right,">=") {}
		protected override bool TryCompute(object left, object right, out object result)
		{
			bool v = false;
			var r = Marshal.TryGreaterOrEqual(left, right, out v);
			result = v;
			return r;
		}
	}

	public sealed class LessOrEqual: InfixOperator
	{
		[UXConstructor]
		public LessOrEqual([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right):
			base(left, right,"<=") {}
		protected override bool TryCompute(object left, object right, out object result)
		{
			bool v = false;
			var r = Marshal.TryLessOrEqual(left, right, out v);
			result = v;
			return r;
		}
	}

	public sealed class Equal: InfixOperator
	{
		[UXConstructor]
		public Equal([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): 
			base(left, right,"==") {}
		protected override bool TryCompute(object left, object right, out object result)
		{
			bool v = false;
			var r = Marshal.TryEqualTo(left, right, out v);
			result = v;
			return r;
		}
	}

	public sealed class NotEqual: InfixOperator
	{
		[UXConstructor]
		public NotEqual([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): 
			base(left, right, "!=") {}
		protected override bool TryCompute(object left, object right, out object result)
		{
			bool v;
			if (!Marshal.TryEqualTo(left, right, out v))
			{
				result = false;
				return false;
			}
			result = !v;
			return true;
		}
	}

	public sealed class LogicalAnd: InfixOperator
	{
		[UXConstructor]
		public LogicalAnd([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): 
			base(left, right, "&&") {}
		protected override bool TryCompute(object left, object right, out object result)
		{
			result = null;
			if (left == null || right == null) return false;
			result = (bool)Marshal.ToBool(left) && (bool)Marshal.ToBool(right);
			return true;
		}
	}

	public sealed class LogicalOr: InfixOperator
	{
		[UXConstructor]
		public LogicalOr([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right): 
			base(left, right, "||") {}
		protected override bool TryCompute(object left, object right, out object result)
		{
			result = null;
			if (left == null || right == null) return false;
			result = (bool)Marshal.ToBool(left) || (bool)Marshal.ToBool(right);
			return true;
		}
	}
	
}