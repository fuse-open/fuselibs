using Uno;

namespace Fuse.Physics
{
	/**
		@mount Physics
	*/
	public class PointAttractor: ForceField
	{
		float3 _offset;
		public float3 Offset
		{
			get { return _offset; }
			set { _offset = value; }
		}

		float _radius = 100.0f;
		public float Radius
		{
			get { return _radius; }
			set { _radius = value; }
		}

		float _strength = 100.0f;
		public float Strength
		{
			get { return _strength; }
			set { _strength = value; }
		}

		float3 TargetPoint
		{
			get { return Vector.Transform(Parent.LocalBounds.Center, Parent.WorldTransform).XYZ + Offset; }
		}

		public bool Exclusive { get; set; }

		float3 DirectionTo(Body b)
		{
			return TargetPoint - b.CenterPosition;	
		}

		float CalcForce(Body b)
		{
			var dist = Vector.Length(DirectionTo(b));
			return Math.Max(_radius - dist, 0) / _radius;
		}

		bool AnyStrongerForce(Body b, float force, World w)
		{
			foreach (var r in w.Rules)
			{
				if (r == this) continue;

				var pa = r as PointAttractor;
				if (pa != null)
				{
					if (pa.CalcForce(b) > force)
						return true;
				}
			}
			return false;
		}

		public string Tag { get; set; }

		float Curve(float x)
		{
			return (float)Math.Sin(x * x * Math.PI);
		}

		protected override void OnUpdate(double deltaTime, World world)
		{
			foreach (var b in World.Bodies)
			{
				if (b.Visual == Parent) continue;
				
				var force = CalcForce(b);

				ForceFieldTrigger.SetForce(this, b, force);

				if (force == 0.0f) continue;

				if (Exclusive)
					if (AnyStrongerForce(b, force, world)) continue;


				var dir = DirectionTo(b);
				var dist = Vector.Length(dir);
				if (dist < 0.5f) return;

				dir /= dist;
				
				dir *= Curve(force) * 50 * _strength;

				var f = dir * (float)deltaTime;
				b.ApplyForce(f);
			}
		}

	}

	
}