using Fuse;
using Uno;
using Uno.UX;
using Fuse.Reactive;

namespace Alive
{
	internal static class ColorFunctions
	{
		public static object Mix(object left, object right, object weight)
		{
			var weightedLeft = Marshal.Multiply(left, Marshal.Subtract(1, weight));
			var weightedRight = Marshal.Multiply(right, weight);

			return Marshal.Add(weightedLeft, weightedRight);
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
		
		protected override object Compute(object left, object right, object weight)
		{
			return ColorFunctions.Mix(left, right, weight);
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

		protected override object Compute(object color, object opacity)
		{
			return ColorFunctions.WithOpacity(color, opacity);
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

		protected override object Compute(object color, object transparency)
		{
			var transparentColor = ColorFunctions.WithOpacity(color, 0);
			return ColorFunctions.Mix(color, transparentColor, transparency);
		}

		public override string ToString()
		{
			return "transparentize(" + Left + ", " + Right + ")";
		}
	}
}