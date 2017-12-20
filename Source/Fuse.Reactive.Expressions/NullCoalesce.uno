using Uno;
using Uno.UX;

namespace Fuse.Reactive
{
	public sealed class NullCoalesce: ComputeExpression
	{
		[UXConstructor]
		public NullCoalesce([UXParameter("Left")] Expression left, [UXParameter("Right")] Expression right)
			: base( new Expression[]{left, right}, Flags.OmitComputeWarning | Flags.AllOptional)
		{}

		protected override bool TryCompute(Expression.Argument[] args, out object result)
		{
			if (args[0].HasValue && args[0].Value != null)
			{
				result = args[0].Value;
				return true;
			}
			
			if (args[1].HasValue)
			{
				result = args[1].Value;
				return true;
			}
			
			result = null;
			return false;
		}
	}
}

