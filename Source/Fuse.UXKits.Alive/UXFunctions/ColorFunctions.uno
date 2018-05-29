using Fuse;
using Uno;
using Uno.UX;
using Fuse.Reactive;

namespace Alive
{
	internal static class ColorFunctions
	{
		public static bool TryMix(object left, object right, object weight, out object result)
		{
			result = null;
			object inverseWeight = null, weightedLeft = null, weightedRight = null;
			if (!Marshal.TrySubtract(1, weight, out inverseWeight) ||
			    !Marshal.TryMultiply(left, inverseWeight, out weightedLeft) ||
			    !Marshal.TryMultiply(right, weight, out weightedRight) ||
			    !Marshal.TryAdd(weightedLeft, weightedRight, out result))
				return false;

			return true;
		}

		public static object WithOpacity(object value, object opacity)
		{
			var color = Marshal.ToFloat4(value);
			color.W = Marshal.ToFloat(opacity);
			return color;
		}
	}

	[UXFunction("mix")]
	public sealed class MixFunction : TernaryOperator
	{
		[UXConstructor]
		public MixFunction(
			[UXParameter("First")] Fuse.Reactive.Expression left,
			[UXParameter("Second")] Fuse.Reactive.Expression right,
			[UXParameter("Third")] Fuse.Reactive.Expression weight
		) : base(left, right, weight) {}

		protected override bool TryCompute(object left, object right, object weight, out object result)
		{
			return ColorFunctions.TryMix(left, right, weight, out result);
		}

		public override string ToString()
		{
			return "mix(" + First + ", " + Second + ", " + Third + ")";
		}
	}

	[UXFunction("withOpacity")]
	public sealed class WithOpacityFunction : BinaryOperator
	{
		[UXConstructor]
		public WithOpacityFunction(
			[UXParameter("Left")] Fuse.Reactive.Expression color,
			[UXParameter("Right")] Fuse.Reactive.Expression opacity
		) : base(color, opacity) {}

		protected override bool TryCompute(object color, object opacity, out object result)
		{
			result = ColorFunctions.WithOpacity(color, opacity);
			return true;
		}

		public override string ToString()
		{
			return "withOpacity(" + Left + ", " + Right + ")";
		}
	}

	[UXFunction("transparentize")]
	public sealed class TransparentizeFunction : BinaryOperator
	{
		[UXConstructor]
		public TransparentizeFunction(
			[UXParameter("Left")] Fuse.Reactive.Expression color,
			[UXParameter("Right")] Fuse.Reactive.Expression transparency
		) : base(color, transparency) {}

		protected override bool TryCompute(object color, object transparency, out object result)
		{
			var transparentColor = ColorFunctions.WithOpacity(color, 0);
			return ColorFunctions.TryMix(color, transparentColor, transparency, out result);
		}

		public override string ToString()
		{
			return "transparentize(" + Left + ", " + Right + ")";
		}
	}
}
