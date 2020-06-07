using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Reactive
{
	/** Optimized base class for reactive functions/operators that take a single argument/operand. */
	public abstract class UnaryOperator: ComputeExpression
	{
		public Expression Operand { get { return GetArgument(0); } }
		protected UnaryOperator(Expression operand, Flags flags = Flags.DeprecatedVirtualFlags | Flags.DeprecatedVirtualUnary )
			: base( new Expression[]{ operand }, flags )
		{ }

		protected UnaryOperator(Expression operand, string name, Flags flags = Flags.None)
			: base( new Expression[]{ operand }, flags, name )
		{ }

		internal override Flags GetFlags()
		{
			return IsOperandOptional ? Flags.Optional0 : Flags.None;
		}

		protected virtual bool IsOperandOptional { get { return false; } }

		/**
			@param result the result of the computation
			@return true if the value could be computed, false otherwise
		*/
		protected virtual bool TryCompute(object operand, out object result)
		{
			Fuse.Diagnostics.Deprecated( " No `TryCompute`, or a deprecated form, overriden. Migrate your code to override the one with `bool` return. ", this );
			result = Compute(operand);
			return true;
		}

		/** @deprecated Override `TryCompute` function. 2017-11-29 */
		protected virtual object Compute(object operand) { return null; }

		protected override sealed bool TryCompute(Argument[] args, out object result)
		{
			return TryCompute(args[0].Value, out result);
		}

		/** @deprecated Override `TryCompute` or don't derive from `UnaryOperator` if you need argument tracking (which is rare). The typical base would be `Expression` and create a `Subscription` derived from `ExpressionListener`. 2017-12-14 */
		protected virtual void OnNewOperand(IListener listener, object operand)
		{
			object result;
			if (TryCompute(operand, out result))
			{
				listener.OnNewData(this, result);
			}
			else
			{
				Fuse.Diagnostics.UserWarning( "Failed to compute value: " + operand, this );
				listener.OnLostData(this);
			}
		}
		internal void InternalOnNewOperand(IListener listener, object operand)
		{ OnNewOperand(listener, operand); }

		/** @deprecated Override `Compute` or don't derive from `UnaryOperator` if you need argument tracking (which is rare). The typical base would be `Expression` and create a `Subscription` derived from `ExpressionListener`. 2017-12-14 */
		protected virtual void OnLostOperand(IListener listener)
		{
			listener.OnLostData(this);
		}
		internal void InternalOnLostOperand(IListener listener)
		{ OnLostOperand(listener); }
	}

	public sealed class Negate: UnaryOperator
	{
		[UXConstructor]
		public Negate([UXParameter("Operand")] Expression operand): base(operand, Flags.None) {}
		protected override bool TryCompute(object operand, out object result)
		{
			return Marshal.TryMultiply(operand, -1, out result);
		}
	}

	public sealed class LogicalNot: UnaryOperator
	{
		[UXConstructor]
		public LogicalNot([UXParameter("Operand")] Expression operand): base(operand, Flags.None) {}

		protected override bool TryCompute(object operand, out object result)
		{
			bool areEqual;
			if (!Marshal.TryEqualTo(operand, true, out areEqual))
			{
				result = false;
				return false;
			}
			result = !areEqual;
			return true;
		}
	}
}
