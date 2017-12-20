using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Reactive
{
	/** Base class for reactive functions/operators that take two arguments/operands. */
	public abstract class BinaryOperator: ComputeExpression
	{
		public Expression Left { get { return GetArgument(0); } }
		public Expression Right { get { return GetArgument(1); } }
		
		protected BinaryOperator(Expression left, Expression right, 
			Flags flags = Flags.DeprecatedVirtualFlags)
			: base( new Expression[]{ left, right}, flags )
		{ }

		protected BinaryOperator(Expression left, Expression right, 
			string name, Flags flags = Flags.None)
			: base( new Expression[]{ left, right}, flags, name )
		{ }
		
		internal override Flags GetFlags()
		{
			return Flags.None |
				(IsLeftOptional ? Flags.Optional0 : Flags.None) |
				(IsRightOptional ? Flags.Optional1 : Flags.None);
		}
		
		protected virtual bool IsLeftOptional { get { return false; } }
		protected virtual bool IsRightOptional { get { return false; } }

		protected virtual bool TryCompute(object left, object right, out object result)
		{
			Fuse.Diagnostics.Deprecated( " No `TryCompute`, or a deprecated form, overriden. Migrate your code to override the one with `bool` return. ", this );
			result = Compute(left, right);
			return true;
		}
		
		/** @deprecated Override the `TryCompute` function. 2017-11-29 */
		protected virtual object Compute(object left, object right) { return null; }

		protected override sealed bool TryCompute(Argument[] args, out object result)
		{
			return TryCompute(args[0].Value, args[1].Value, out result);
		}
	}
}
