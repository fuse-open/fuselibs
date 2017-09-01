using Uno;
using Uno.UX;
using Fuse.Animations;

namespace Fuse.Motion.Simulation
{
	class EasingMotion<T> : DestinationSimulation<T>
	{
		Fuse.Internal.Blender<T> _blender = Fuse.Internal.BlenderMap.Get<T>();
		const float _zeroTolerance = 1e-05f;

		public static EasingMotion<T> CreateNormalized()
		{
			var q = new EasingMotion<T>();
			q.NominalDistance = 1;
			return q;
		}
		
		public static EasingMotion<T> CreateRadians()
		{
			var q = new EasingMotion<T>();
			q.NominalDistance = Math.PIf;
			return q;
		}
		
		public static EasingMotion<T> CreatePoints()
		{
			var q = new EasingMotion<T>();
			q.NominalDistance = 500;
			return q;
		}
		
		static public EasingMotion<T> CreateUnit( MotionUnit unit )
		{
			switch(unit)
			{
				case MotionUnit.Points: return CreatePoints();
				case MotionUnit.Normalized: return CreateNormalized();
				case MotionUnit.Radians: return CreateRadians();
			}
			throw new Exception( "Unsupported unit type: " +unit );
		}
		
		bool _isDirty = true;
		bool _isStatic = true;
		public bool IsStatic
		{
			get { return _isStatic && !_isDirty; }
		}
		
		Easing _easing = Fuse.Animations.Easing.Linear;
		[UXContent]
		public Easing Easing
		{
			get { return _easing; }
			set
			{
				_easing = value;
			}
		}
		
		double _progress = 1;
		double _progressSpeed = 0;
		
		T _transitionPosition;
		T _transitionVelocity;
		double _transitionTime = 1;
		double _transitionRemain = 0;
		
		//is the motion locked to the easing
		bool _isLocked = true;
		
		public void Update( double elapsed )
		{
			if (_isDirty)
				UpdateDestination(false);
				
			_progress = Math.Min(1, _progress + _progressSpeed * elapsed);
			
			if (elapsed >= _transitionRemain)
				_isLocked = true;
			
			var desiredPosition = _blender.Lerp(_source, _destination, _easing.Map((float)_progress) );
			var prevPos = _blender.Lerp(_source, _destination, 
				_easing.Map((float)_progress - 0.001f) );
			var desiredVelocity = _blender.Weight( _blender.Sub(desiredPosition, prevPos), 
				1 / 0.001f );

			if (_isLocked)
			{
				_position = desiredPosition;
				_velocity = desiredVelocity;
				
				if (_progress >= 1)
				{
					_position = _destination;
					_velocity = _blender.Zero;
					_isStatic = true;
					_isLocked = true;
					_progress = 1;
				}
				
				return;
			}
			
			_transitionPosition = _blender.Add( _transitionPosition, 
				_blender.Weight( Velocity, elapsed ) );

			_transitionRemain -= elapsed;
			var rtp = (float)(_transitionRemain / _transitionTime);
			var tp = rtp;
			
			_velocity = _blender.Lerp(desiredVelocity, _transitionVelocity, tp);
			_position = _blender.Lerp(desiredPosition, _transitionPosition, tp);
		}

		T _position;
		public T Position
		{
			get { return _position; }
			set
			{
				if (_blender.Distance(_position,value) > _zeroTolerance)
					_isDirty = true;
				_position = value;
			}
		}
		
		T _velocity;
		public T Velocity
		{
			get { return _velocity; }
			set 
			{ 
				if (_blender.Distance(_velocity,value) > _zeroTolerance)
					_isDirty = true;
				_velocity = value;
			}
		}
		
		T _destination;
		public T Destination
		{
			get { return _destination; }
			set 
			{ 
				if (_blender.Distance(_destination,value) > _zeroTolerance)
					_isDirty = true;
				_destination = value;
			}
		}
		
		public void Start()
		{
			UpdateDestination(true);
		}
		
		T _source;
		void UpdateDestination(bool start)
		{
			_isDirty = false;
			
			var shouldLock = _blender.Length(Velocity) < _zeroTolerance;
			
			_source = Position;
			_isStatic = false;
			
			var dist = _blender.Distance( _destination, Position );
			var partial = dist  / _nominalDistance;
			
			var lenDuration = Duration * Math.Pow(partial, _durationExp);
			if (lenDuration < _zeroTolerance)
			{
				//even if there is velocity there is nothing we can do but just lock in place (this situation is unlikely)
				_isStatic = true;
				Position = _destination;
				Velocity = _blender.Zero;
				return;
			}
			else if (partial < 1 && !shouldLock)
			{
				//if we are within the nominalDistance assume we are partially through the easing already
				_progress = 1 - partial;
				_progressSpeed = 1 / lenDuration;
				_isLocked = false;
			}
			else
			{
				_progress = 0;
				_progressSpeed = 1 / lenDuration;
				_isLocked = shouldLock;
			}
			
			//limit transition time to expected time left
			_transitionRemain = _transitionTime = Math.Min( Duration / 2, lenDuration );
			_transitionPosition = Position;
			_transitionVelocity = Velocity;
			
			/*debug_log "Update: " +
				" transRemain=" + _transitionRemain +
				" transPosition=" + _transitionPosition +
				" transVelocity=" + _transitionVelocity +
				" Locked=" + _isLocked +
				" progress=" + _progress +
				" progressSpeed=" + _progressSpeed +
				" src=" + _source +
				" dst=" + _destination;*/
		}

		float _duration = 0.5f;
		public float Duration 
		{ 
			get { return _duration; }
			set { _duration = value; }
		}
		
		float _durationExp = 1;
		public float DurationExp
		{
			get { return _durationExp; }
			set { _durationExp = value; }
		}
	
		float _nominalDistance = 1;
		public float NominalDistance
		{
			get { return _nominalDistance; }
			set { _nominalDistance = value; }
		}

		public void Reset( T destination )
		{
			_position = destination;
			_destination = destination;
			_velocity = _blender.Zero;
			_isStatic = true;
			_isDirty = false;
		}
	}
	
	//public class EasingMotionFloat2 : EasingMotion<float2> { }
}
