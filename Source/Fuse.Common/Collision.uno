using Uno;
namespace Fuse
{
	public static class Collision
	{
		public static bool RayIntersectsBox(Ray ray, Box box, out float distance)
		{
			//Source: Real-Time Collision Detection by Christer Ericson
			//Reference: Page 179

			distance = 0.f;
			float tmax = float.MaxValue;

			if (Math.Abs(ray.Direction.X) < float.ZeroTolerance)
			{
				if (ray.Position.X < box.Minimum.X || ray.Position.X > box.Maximum.X)
				{
					distance = 0.f;
					return false;
				}
			}
			else
			{
				float inverse = 1.0f / ray.Direction.X;
				float t1 = (box.Minimum.X - ray.Position.X) * inverse;
				float t2 = (box.Maximum.X - ray.Position.X) * inverse;

				if (t1 > t2)
				{
					float temp = t1;
					t1 = t2;
					t2 = temp;
				}

				distance = Math.Max(t1, distance);
				tmax = Math.Min(t2, tmax);

				if (distance > tmax)
				{
					distance = 0.f;
					return false;
				}
			}

			if (Math.Abs(ray.Direction.Y) < float.ZeroTolerance)
			{
				if (ray.Position.Y < box.Minimum.Y || ray.Position.Y > box.Maximum.Y)
				{
					distance = 0.f;
					return false;
				}
			}
			else
			{
				float inverse = 1.0f / ray.Direction.Y;
				float t1 = (box.Minimum.Y - ray.Position.Y) * inverse;
				float t2 = (box.Maximum.Y - ray.Position.Y) * inverse;

				if (t1 > t2)
				{
					float temp = t1;
					t1 = t2;
					t2 = temp;
				}

				distance = Math.Max(t1, distance);
				tmax = Math.Min(t2, tmax);

				if (distance > tmax)
				{
					distance = 0.f;
					return false;
				}
			}

			if (Math.Abs(ray.Direction.Z) < float.ZeroTolerance)
			{
				if (ray.Position.Z < box.Minimum.Z || ray.Position.Z > box.Maximum.Z)
				{
					distance = 0.f;
					return false;
				}
			}
			else
			{
				float inverse = 1.0f / ray.Direction.Z;
				float t1 = (box.Minimum.Z - ray.Position.Z) * inverse;
				float t2 = (box.Maximum.Z - ray.Position.Z) * inverse;

				if (t1 > t2)
				{
					float temp = t1;
					t1 = t2;
					t2 = temp;
				}

				distance = Math.Max(t1, distance);
				tmax = Math.Min(t2, tmax);

				if (distance > tmax)
				{
					distance = 0.f;
					return false;
				}
			}

			return true;
		}
	}
}
