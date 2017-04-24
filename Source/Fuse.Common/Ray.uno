using Uno;

namespace Fuse
{
	public struct Ray
	{
		public /*readonly*/ float3 Position;
		public /*readonly*/ float3 Direction;

		public Ray(float3 pos, float3 dir)
		{
			Position = pos;
			Direction = dir;
		}

		public static Ray Normalize(Ray ray)
		{
			return new Ray(ray.Position, Vector.Normalize(ray.Direction));
		}

		public static Ray Transform(Ray ray, float4x4 transform)
		{
			return new Ray(Vector.Transform(float4(ray.Position, 1.0f), transform).XYZ, Vector.Normalize(Vector.TransformNormal(ray.Direction, transform)));
		}
	}
}
