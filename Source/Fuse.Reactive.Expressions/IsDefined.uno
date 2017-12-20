using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Reactive
{
	[UXFunction("isDefined")]
	/** 
		Test if a value is defined the context, returning `true` or `false`. 
		
		This can be used to check if a value is available yet in the data context, for example `isDefined({a})`.
		
		If the value exists but is null then `true` will still be returned. Consider using `isNull` if you wish to exclude null as well.
		
		@advanced
	*/
	public sealed class IsDefined: ComputeExpression
	{
		public Expression Operand { get { return GetArgument(0); } }
		
		[UXConstructor]
		public IsDefined([UXParameter("Operand")] Expression operand)
			: base( new Expression[]{ operand }, Flags.OmitComputeWarning | Flags.AllOptional )
		{ }

		protected sealed override bool TryCompute(Expression.Argument[] args, out object result)
		{
			result = args[0].HasValue;
			return true;
		}
	}
	
	[UXFunction("isNull")]
	/** Returns false if the value exists and is non-null, true otherwise.
	
		This is the same condition used in the NullCoalesce operator:
		
			expr ?? res
			
		Is the same as:
		
			isNull(expr) ? res : expr
	*/
	public sealed class IsNull : UnaryOperator
	{
		[UXConstructor]
		public IsNull([UXParameter("Operand")] Expression operand)
			: base(operand, "isNull", Flags.Optional0) {}
		protected override bool TryCompute(object operand, out object result)
		{
			result = operand == null;
			return true;
		}
	}
	
	[UXFunction("nonNull")]
	/** Returns the value if it isn't null otherwise doesn't evaluate.
	
		This is a special use function in cases where you need to deal temporarily with null values that later become non-null. Instead of the null creating errors in an expression chain, this causes the expression to not evaluate at all.
		
		@advanced
	*/
	public sealed class NonNull : ComputeExpression
	{
		public Expression Operand { get { return GetArgument(0); } }
		
		[UXConstructor]
		public NonNull([UXParameter("Operand")] Expression operand)
			: base( new Expression[]{ operand }, Flags.OmitComputeWarning )
		{ }
		
		protected override bool TryCompute(Expression.Argument[] args, out object result)
		{
			result = args[0].Value;
			return args[0].Value != null;
		}
	}
	
}
