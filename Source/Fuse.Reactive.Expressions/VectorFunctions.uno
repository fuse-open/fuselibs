using Uno.UX;

namespace Fuse.Reactive
{
	public class Vector2: BinaryOperator
	{
		[UXConstructor]
		public Vector2([UXParameter("X")] Expression x, [UXParameter("Y")] Expression y): base(x, y) { }

		protected override object Compute(object left, object right)
		{
			if (left is Size || right is Size) return new Size2(Marshal.ToSize(left), Marshal.ToSize(right));
			return float2(Marshal.ToFloat(left), Marshal.ToFloat(right));
		}

		public override string ToString()
		{
			return "(" + Left + ", " + Right + ")";
		}
	}

	public class Vector3: TernaryOperator
	{
		[UXConstructor]
		public Vector3([UXParameter("X")] Expression x, [UXParameter("Y")] Expression y, [UXParameter("Z")] Expression z) : base(x,y,z) {}

		protected override object Compute(object first, object second, object third)
		{
			return float3(Marshal.ToFloat(first), Marshal.ToFloat(second), Marshal.ToFloat(third));
		}

		public override string ToString()
		{
			return "(" + First + ", " + Second + ", " + Third + ")";
		}
	}

	public class Vector4: QuaternaryOperator
	{
		[UXConstructor]
		public Vector4([UXParameter("X")] Expression x, [UXParameter("Y")] Expression y, [UXParameter("Z")] Expression z, [UXParameter("W")] Expression w) : base(x,y,z,w) {}

		protected override object Compute(object first, object second, object third, object fourth)
		{
			return float4(Marshal.ToFloat(first), Marshal.ToFloat(second), Marshal.ToFloat(third), Marshal.ToFloat(fourth));
		}

		public override string ToString()
		{
			return "(" + First + ", " + Second + ", " + Third + ", " + Fourth + ")";
		}
	}
}