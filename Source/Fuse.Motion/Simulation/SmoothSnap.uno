using Uno;

namespace Fuse.Motion.Simulation
{
	class SmoothSnap<T> : DestinationSimulation<T>
	{
		Fuse.Internal.Blender<T> _blender = Fuse.Internal.BlenderMap.Get<T>();
		const float _zeroTolerance = 1e-05f;

		public static SmoothSnap<T> CreateNormalized()
		{
			var s = new SmoothSnap<T>(_zeroTolerance);
			s._speedMin = 0.2f;
			s._speedDropoutDistance = 0.4f;
			s._speed = 3.5f;
			return s;
		}
		
		public static SmoothSnap<T> CreateRadians()
		{
			var s = new SmoothSnap<T>(_zeroTolerance);
			s._speedMin = 0.2f * Math.PIf;
			s._speedDropoutDistance = 0.4f * Math.PIf;
			s._speed = 3.5f * Math.PIf;
			return s;
		}
		
		public static SmoothSnap<T> CreatePoints()
		{
			var s = new SmoothSnap<T>(_zeroTolerance);
			s._speedMin = 25f;
			s._speedDropoutDistance = 100f;
			s._speed = 600;
			return s;
		}
		
		static public SmoothSnap<T> CreateUnit( MotionUnit unit )
		{
			switch(unit)
			{
				case MotionUnit.Points: return CreatePoints();
				case MotionUnit.Normalized: return CreateNormalized();
				case MotionUnit.Radians: return CreateRadians();
			}
			throw new Exception( "Unsupported unit type: " +unit );
		}
		
		float _scale = 1;
		public SmoothSnap( float scale = _zeroTolerance )
		{
			_scale = scale;
		}
		
		public T Position { get; set; }
		public T Velocity { get; set; }
		public T Destination { get; set; }
		
		public void Reset( T destination )
		{
			Destination = destination;
			Velocity = _blender.Zero;
			Position = destination;
		}
		
		public void Start()
		{
			//nothing
		}
		
		float _speedMin = 25;
		//lerp between _speed and _speedMin over this distance from destination
		float _speedDropoutDistance = 100;
		
		public float SpeedDropoutDistance
		{
			get { return _speedDropoutDistance; }
			set { _speedDropoutDistance = value; }
		}
		
		float _speed = 600;
		public float Speed 
		{ 
			get { return _speed; }
			set { _speed = value;  }
		}

		/*
			Determine speed needed to cover Distance in Duration with snapping formula
				d = v_0 * t + a * t ^ 2 / 2
				a = (v_1 - v_0) / t
				
				v_0 = - (t * v_1 - 2 *d) / t
				
			This is not a stable value, and this must be called after other items are configured (Distance)
		*/
		public void SetDuration( float t )
		{
			var s = - (t * _speedMin - 2 * _speedDropoutDistance) / t;
			//too low usually implies a unit mismatch, but be safe here
			Speed = Math.Max(s, _speedMin);
		}
		
		public bool IsStatic
		{
			get
			{		
				return _blender.Length( _blender.Sub( Destination, Position ) ) < _scale;
			}
		}
		
		public void Update( double elapsed )
		{
			var off = _blender.Sub( Destination, Position);
			double offLen;
			var offUnit = _blender.ToUnit( off, out offLen );
			
			var useSpeed = Speed;
			if (offLen < _speedDropoutDistance)
				useSpeed = (float)offLen / _speedDropoutDistance * (Speed - _speedMin) + _speedMin;
		
			if (offLen < (useSpeed * elapsed))
			{
				Position = Destination;
				Velocity = _blender.Zero;
				return;
			}
			
			//TODO: acceleration to be friendly with current velocity (huge jerk now on non-stopped snap)
			
			Velocity = _blender.Weight( offUnit, useSpeed );
			Position = _blender.Add( Position, _blender.Weight( Velocity, (float)elapsed ) );
		}
	}
}
