using Uno;

namespace Fuse.Motion.Simulation
{
	[Flags]
	public enum SampleFlags
	{
		None = 0,
		Tentative = 1 << 0,
		//the pointer has been released
		Release = 1 << 1,
	}
		
	/**
		Determines the appropriate velocity from pointerDown/Move/Release events.
	*/
	public class PointerVelocity<T>
	{
		Fuse.Internal.Blender<T> _blender = Fuse.Internal.BlenderMap.Get<T>();

		//any speed under this is considered not moving. This value actually correlates
		//to 1 point per frame, the point at which movement is truly indistinguishable from not-moving
		double _speedThreshold = 60;
		
		float _period = 0.12f;
		public float Period
		{
			get { return _period; }
			set { _period = value; }
		}
		
		T _velocity;
		public T CurrentVelocity
		{
			get { return _velocity; }
			set { _velocity = value; }
		}

		const float _zeroTolerance = 1e-05f;

		T _currentLocation, _startLocation;
		public T AverageVelocity
		{
			get
			{
				var v = _blender.Sub( _currentLocation, _startLocation );
				double length;
				var unit = _blender.ToUnit( v, out length );
				var s = _totalTime > _zeroTolerance && length > _zeroTolerance ? 
					(float)(length / _totalTime) : 0;
				return _blender.Weight( unit, (float)s );
			}
		}
		
		public double TotalDistance
		{
			get { return _totalDistance; }
		}
		
		float _accelThreshold = 1000;
		float _accelLimit = 2000;
		float _accelFactor = 1.5f;
		
		float _inSpeedLimit = 2000;
		float _speedDistanceThreshold = 50;
		
		double _totalTime;
		double _totalDistance;
		double _prevTime;
		public void Reset( T location0 )
		{
			Reset( location0, _blender.Zero, 0 );
		}
		
		public void Reset( T location0, T velocity0, double currentTime = 0 )
		{
			_velocity = velocity0;
			_totalTime = 0;
			_startLocation = _currentLocation = location0;
			_totalDistance = 0;
			_prevTime = currentTime;
		}
		
		public void AddSampleTime( T location, double timestamp, SampleFlags flags = SampleFlags.None )
		{
			AddSample( location, timestamp - _prevTime, flags );
			_prevTime = timestamp;
		}
		
		public void AddSample( T location, double elapsed, SampleFlags flags = SampleFlags.None )
		{
			var diff = _blender.Sub( location, _currentLocation );
			double length;
			var unit = _blender.ToUnit( diff, out length );
			if (length < _zeroTolerance)
				unit = _blender.Zero;
			_totalDistance += length;
			_currentLocation = location;

			//ignore if release didn't move, since it may have time (like on Android)
			if (flags.HasFlag(SampleFlags.Release) && length < 1)	
				return;
				
			if (elapsed < _zeroTolerance)
				return;
			
			float speed = (float)(length / elapsed); 
			//assume user completely stopped if they go too slow
			if (speed < _speedThreshold) {
				_velocity = _blender.Zero;
				_totalDistance = 0;
				return;
			}
		
			//limit speed based on distance offset to prevent short taps from flying
			var tdP = Math.Clamp( _totalDistance / _speedDistanceThreshold, 0, 1);
			speed = Math.Min( (float)(_inSpeedLimit * tdP), speed );
			
			//apply speed acceleration
			float aSpeed = speed;
			if (tdP >= 1)
			{
				var accelRange = Math.Clamp( speed, _accelThreshold, _accelLimit ) / (_accelLimit - _accelThreshold);
				var accel = accelRange * _accelFactor;
				aSpeed = speed * accel;
			}

			var sample = _blender.Weight( unit, aSpeed );
			ApplySample( sample, elapsed );
		}
		
		void ApplySample( T sample, double elapsed )
		{
			//this may cause tap jumpiness, but without it quick swipe response is terrible
			if (_totalTime < _zeroTolerance)
			{
				_velocity = sample;
			}	
			else
			{
				var alpha = Fuse.Internal.Statistics.ContinuousFilterAlpha( elapsed, _period );
				_velocity = _blender.Lerp( _velocity, sample, alpha ); //an exponential moving average
			}
			
			_totalTime += elapsed;
		}
	}
}
