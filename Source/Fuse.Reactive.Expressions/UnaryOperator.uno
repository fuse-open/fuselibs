using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Reactive
{
	/** Optimized base class for reactive functions/operators that take a single argument/operand. */
	public abstract class UnaryOperator: ComputeExpression
	{
		public Expression Operand { get { return GetArgument(0); } }
		protected UnaryOperator(Expression operand, Flags flags = Flags.DeprecatedVirtualFlags )
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
		protected virtual bool Compute(object operand, out object result)
		{
			Fuse.Diagnostics.Deprecated( " No `Compute`, or a deprecated form, overriden. Migrate your code to override the one with `bool` return. ", this );
			result = Compute(operand);
			return true;
		}
		
		/** @deprecated Override the other `Compute` function. 2017-11-29 */
		protected virtual object Compute(object operand) { return null; }

		protected override sealed bool Compute(Argument[] args, out object result)
		{
			return Compute(args[0].Value, out result);
		}
	}

	public sealed class Negate: UnaryOperator
	{
		public Negate([UXParameter("Operand")] Expression operand): base(operand) {}
		protected override bool Compute(object operand, out object result)
		{
			result = Marshal.Multiply(operand, -1);
			return true;
		}
	}
}
