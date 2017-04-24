using Uno;

namespace Fuse
{
	public struct Box
	{
		public float3 Minimum, Maximum;

		public Box(float3 min, float3 max)
		{
			Minimum = min;
			Maximum = max;
		}

		public float3 Center
		{
			get { return (Minimum + Maximum) * 0.5f; }
		}

		public static Box Transform(Box box, float4x4 transform)
		{
			float3 A = Vector.Transform(float4(box.Minimum.X, box.Minimum.Y, box.Minimum.Z, 1.0f), transform).XYZ;
			float3 B = Vector.Transform(float4(box.Maximum.X, box.Minimum.Y, box.Minimum.Z, 1.0f), transform).XYZ;
			float3 C = Vector.Transform(float4(box.Maximum.X, box.Maximum.Y, box.Minimum.Z, 1.0f), transform).XYZ;
			float3 D = Vector.Transform(float4(box.Minimum.X, box.Maximum.Y, box.Minimum.Z, 1.0f), transform).XYZ;
			float3 E = Vector.Transform(float4(box.Minimum.X, box.Minimum.Y, box.Maximum.Z, 1.0f), transform).XYZ;
			float3 F = Vector.Transform(float4(box.Maximum.X, box.Minimum.Y, box.Maximum.Z, 1.0f), transform).XYZ;
			float3 G = Vector.Transform(float4(box.Maximum.X, box.Maximum.Y, box.Maximum.Z, 1.0f), transform).XYZ;
			float3 H = Vector.Transform(float4(box.Minimum.X, box.Maximum.Y, box.Maximum.Z, 1.0f), transform).XYZ;

			return new Box(
				Math.Min(Math.Min(Math.Min(Math.Min(Math.Min(Math.Min(Math.Min(A, B), C), D), E), F), G), H),
				Math.Max(Math.Max(Math.Max(Math.Max(Math.Max(Math.Max(Math.Max(A, B), C), D), E), F), G), H));
		}
	}
}
