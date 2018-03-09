using Uno;
namespace Fuse
{
	public static class Collision
	{
		public static bool RayIntersectsBox(Ray ray, Box box, out float distance)
		{
			//Source: Real-Time Collision Detection by Christer Ericson
			//Reference: Page 179
			const float zeroTolerance = 1e-05f;

			distance = 0.f;
			float tmax = float.MaxValue;

			if (Math.Abs(ray.Direction.X) < zeroTolerance)
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

			if (Math.Abs(ray.Direction.Y) < zeroTolerance)
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

			if (Math.Abs(ray.Direction.Z) < zeroTolerance)
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

		/**
			Calculate the intersection of two lines.  `p1`/`p2` are a point on the lines. `v1`/`v2` are the slopes of the lines (they need not be normalized).
			
			@return true if `r` contains the intersection point, false if the lines are parallel or coincident.
		*/
		public static bool LineLineIntersection( float2 p1, float2 v1, float2 p2, float2 v2, out float2 r )
		{
			// Get A,B,C of first line - points : ps1 to pe1
			float A1 = v1.Y;
			float B1 = -v1.X;
			float C1 = A1*p1.X + B1*p1.Y;

			// Get A,B,C of second line - points : ps2 to pe2
			float A2 = v2.Y;
			float B2 = -v2.X;
			float C2 = A2*p2.X + B2*p2.Y;

			// Get delta and check if the lines are parallel
			float delta = A1*B2 - A2*B1;
			if( Math.Abs(delta) < 1e-4 )
			{
				r = float2(0);
				return false;
			}

			// now return the Vector2 intersection point
			r = float2(
				(B2*C1 - B1*C2)/delta,
				(A1*C2 - A2*C1)/delta);
			return true;
		}
	}
}
