using Uno;
using Fuse;

namespace Fuse.Motion.Simulation
{
	class Friction<T> : MotionSimulation<T>
	{
		//values suitable for flat pixel movement, like ScrollView
		static public Friction<T> CreatePoints()
		{
			var n = new Friction<T>();
			n.SpeedDropout = 25f;
			n.KineticDeceleration = 60f;
			n.LowFluidDeceleration = 1.5f;
			n.HighFluidDeceleration = 0;
			return n;
		}
		
		static public Friction<T> CreateRadians()
		{
			var n = new Friction<T>();
			n.SpeedDropout = 0.02f;
			n.KineticDeceleration = 2;
			n.LowFluidDeceleration = 0.8f;
			n.HighFluidDeceleration = 0;
			return n;
		}
		
		static public Friction<T> CreateNormalized()
		{
			var n = new Friction<T>();
			n.SpeedDropout = 25f/500f;
			n.KineticDeceleration = 60f/500f;
			n.LowFluidDeceleration = 1.5f;
			n.HighFluidDeceleration = 0;
			return n;
		}
		
		static public Friction<T> CreateUnit( MotionUnit unit )
		{
			switch(unit)
			{
				case MotionUnit.Points: return CreatePoints();
				case MotionUnit.Normalized: return CreateNormalized();
				case MotionUnit.Radians: return CreateRadians();
			}
			throw new Exception( "Unsupported unit type: " +unit );
		}
		
		
		Fuse.Internal.Blender<T> _blender = Fuse.Internal.BlenderMap.Get<T>();
		
		float _speedDropout = 25f;
		public float SpeedDropout
		{
			get { return _speedDropout; }
			set { _speedDropout = value; }
		}

		float _kineticDeceleration = 60.0f;
		public float KineticDeceleration 
		{
			get { return _kineticDeceleration; }
			set { _kineticDeceleration = value; }
		}
		
		float _lowFluidDeceleration = 1.5f;
		public float LowFluidDeceleration
		{
			get { return _lowFluidDeceleration; }
			set { _lowFluidDeceleration = value; }
		}
		
		float _highFluidDeceleration = 0f; //not used: see note in Update
		public float HighFluidDeceleration
		{
			get { return _highFluidDeceleration; }
			set { _highFluidDeceleration = value; }
		}

		T _velocity;
		public T Velocity
		{
			get { return _velocity; }
			set
			{
				_velocity = value;
				_isStatic = false;
			}
		}
		
		T _position;
		public T Position
		{
			get { return _position; }
			set { _position = value; }
		}
		
		bool _isStatic;
		public bool IsStatic
		{
			get { return _isStatic; }
		}
		
		public void Update(double elapsed)
		{
			var step = _blender.Weight( _velocity, (float)elapsed );
			_position = _blender.Add( _position, step );
			
			//calculate fluid deceleration
			var linear = _blender.Length(_velocity);
			if (linear < _speedDropout) 
			{
				_velocity = _blender.Zero;
				_isStatic = true;
				return;
			}
			
			var fluid = _kineticDeceleration + 
				linear * _lowFluidDeceleration;
				//linear * linear * highFluidDeceleration; //too large over FrameInterval increments, need to solve a differential equation for this
			linear += -fluid * (float)elapsed;
			if (linear < _speedDropout) 
			{
				_velocity = _blender.Zero;
				_isStatic = true;
				return;
			}
			_velocity = _blender.UnitWeight(_velocity, linear);
		}
	}
}
