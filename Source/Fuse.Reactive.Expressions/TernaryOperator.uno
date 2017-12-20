using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Reactive
{
	/** Base class for reactive functions/operators that take three arguments/operands. */
	public abstract class TernaryOperator: ComputeExpression
	{
		public Expression First { get { return GetArgument(0); } }
		public Expression Second { get { return GetArgument(1); } }
		public Expression Third { get { return GetArgument(2); } }

		protected TernaryOperator(Expression first, Expression second, Expression third,
				Flags flags = Flags.DeprecatedVirtualFlags )
			: base( new Expression[]{ first, second, third }, flags )
		{
		}

		internal override Flags GetFlags()
		{
			return Flags.None |
				(IsFirstOptional ? Flags.Optional0 : Flags.None) |
				(IsSecondOptional ? Flags.Optional1 : Flags.None) |
				(IsThirdOptional ? Flags.Optional2 : Flags.None);
		}
		

		/**  DEPRECATED: 2017-12-14  Use flags in constructor instead. These virtuals are only used if DeprecatedVirtualFlags specified, and only at initialization of subscription. */
		protected virtual bool IsFirstOptional { get { return false; } }
		protected virtual bool IsSecondOptional { get { return false; } }
		protected virtual bool IsThirdOptional { get { return false; } }

		protected virtual bool TryCompute(object first, object second, object third, out object result)
		{
			Fuse.Diagnostics.Deprecated( " No `TryCompute`, or a deprecated form, overriden. Migrate your code to override the one with `bool` return. ", this );
			result = Compute(first, second, third);
			return true;
		}
		
		/** @deprecated Override the `TryCompute` function. 2017-11-29 */
		protected virtual object Compute(object first, object second, object third) { return null; }

		protected override sealed bool TryCompute(Argument[] args, out object result)
		{
			return TryCompute(args[0].Value, args[1].Value, args[2].Value, out result);
		}
	}
}
