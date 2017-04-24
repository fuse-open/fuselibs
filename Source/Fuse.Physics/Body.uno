using Uno;
using Uno.Collections;
using Fuse.Elements;

namespace Fuse.Physics
{
	internal class Body
	{
		static readonly PropertyHandle _frictionHandle = Properties.CreateHandle();

		internal static float GetFriction(Visual n)
		{
			var f = n.Properties.Get(_frictionHandle);
			if (f == null) return 0.05f;
			else return (float)f;
		}

		internal static void SetFriction(Visual n, float friction)
		{
			n.Properties.Set(_frictionHandle, friction);
		}

		internal float Friction
		{
			get { return GetFriction(Visual); }
			set { SetFriction(Visual, value); }
		}
		
		internal readonly World World;
		internal readonly Visual Visual;

		internal int PinCount;

		readonly Translation _translation;

		internal float3 CenterPosition
		{
			get { return Vector.Transform(Visual.LocalBounds.Center, Visual.WorldTransform).XYZ; }
		}

		internal Body(World world, Visual node) 
		{
			Visual = node;
			_translation = new Translation();
			Visual.Children.Add(_translation);

			World = world;
		}

		internal void Dispose()
		{
			Visual.Children.Remove(_translation);
		}

		internal static Body Pin(Visual n)
		{
			return World.FindWorld(n).PinBody(n);
		}

		internal void Unpin()
		{
			World.UnpinBody(this);
		}

		object _motionOwner = null;

		internal bool TryLockMotion(object owner)
		{
			if (_motionOwner != null) return false;

			_motionOwner = owner;
			return true;
		}

		internal void UnlockMotion()
		{
			_motionOwner = null;
		}

		internal void Move(float3 delta)
		{
			_position += delta;
		}

		Element _constraint;

		internal void ConstrainToBounds(Element elm)
		{
			_constraint = elm;
			
		}

		internal void ApplyForce(float3 force)
		{
			_velocity += force;
		}

		internal float3 Position { get { return _position; } }

		internal float3 WorldPosition 
		{
			get 
			{
				return Visual.WorldPosition;
			}
		}
 
		float3 _velocity;
		float3 _position;

		internal void Update(double deltaTime)
		{
			ApplyFriction(deltaTime);
			ApplyMotion(deltaTime);

			_translation.Vector = _position;

			if (_constraint != null)
			{
				var p = WorldPosition;
				var s = float2(0);
				if (Visual is Element)
				{
					s = (Visual as Element).ActualSize;
				}

				var bmin = _constraint.WorldPosition;
				var bmax = float3(_constraint.ActualSize,0) + bmin;

				p.X = Math.Max(p.X, bmin.X);
				p.Y = Math.Max(p.Y, bmin.Y);
				p.Z = Math.Max(p.Z, bmin.Z);

				p.X = Math.Min(p.X, bmax.X-s.X);
				p.Y = Math.Min(p.Y, bmax.Y-s.Y);
				p.Z = Math.Max(p.Z, bmax.Z);

				var d = (p-WorldPosition);

				if (Vector.Length(d) > 0.01)
				{
					_position += d;
					_translation.Vector = _position;
					_velocity = float3(0);
				}
			}
		}

		void ApplyFriction(double deltaTime)
		{	
			var friction = Friction;

			for (double t = 0; t < deltaTime; t += 0.001)
			{
				_velocity *= 1.0f - friction;
			}
		}

		void ApplyMotion(double deltaTime)
		{
			if (_motionOwner != null) return;
			_position += _velocity * (float)deltaTime * 5;
		}
	}

}