using Uno;

namespace Fuse.Motion.Simulation
{
	/**
		Only valid for float | double
	*/
	class AngularAdapter<T> : DestinationSimulation<T>
	{
		DestinationSimulation<T> _impl;
		
		public AngularAdapter( DestinationSimulation<T> impl )
		{
			_impl = impl;
		}
		
		Fuse.Internal.ScalarBlender<T> _blender = Fuse.Internal.BlenderMap.GetScalar<T>();
		
		public bool IsStatic 
		{
			get { return _impl.IsStatic; }
		}
		
		public void Update( double elapsed )
		{
			 _impl.Update(elapsed);
		}
		
		public T Position
		{
			get { return _impl.Position; }
			set 
			{ 
				_impl.Position = value;
				Wrap();
			}
		}
		
		public T Velocity
		{
			get { return _impl.Velocity; }
			set 
			{ 
				_impl.Velocity = value;
			}
		}
		
		public T Destination
		{
			get { return _impl.Destination; }
			set 
			{ 	
				_impl.Destination = value;
				Wrap();
			}
		}
		
		public void Reset( T value )
		{
			_impl.Reset(value);
		}

		public void Start()
		{
			_impl.Start();
		}
		/*
			Finds the shorter angle to get to the destination and adjusts position. Position is always
			adjusted and destination left as is so the true value of this control actually tends towards
			destination.
		*/
		void Wrap()
		{
			var pos = _blender.ToDouble(_impl.Position);
			var dst = _blender.ToDouble(_impl.Destination);
			
			var rpos = Math.Mod(pos, Math.PI*2);
			var rdst = Math.Mod(dst, Math.PI*2);
			var diff = rpos - rdst;
			
			if (diff > Math.PI)
				diff = diff - (Math.PI*2);
			else if( diff < -Math.PI)
				diff = diff + (Math.PI*2);
				
			var npos = dst + diff;
			_impl.Position = _blender.FromDouble( npos );
		}
		
	}
	
	class AdapterMultiplier<T> : DestinationSimulation<T>
	{
		Fuse.Internal.ScalarBlender<T> _blender = Fuse.Internal.BlenderMap.GetScalar<T>();
		DestinationSimulation<T> _impl;
		double _multiplier;
		
		public AdapterMultiplier( DestinationSimulation<T> impl, double multiplier )
		{
			_impl = impl;
			_multiplier = multiplier;
		}
		
		public bool IsStatic 
		{
			get { return _impl.IsStatic; }
		}
		
		public void Update( double elapsed )
		{
			 _impl.Update(elapsed);
		}
		
		T In( T val )
		{
			return _blender.ScalarMult(val, _multiplier);
		}
		
		T Out( T val )
		{
			return _blender.ScalarMult(val, 1/_multiplier);
		}
		
		public T Position
		{
			get { return Out(_impl.Position); }
			set { _impl.Position = In(value); }
		}
		
		public T Velocity
		{
			get { return Out(_impl.Velocity); }
			set { _impl.Velocity = In(value); }
		}
		
		public T Destination
		{
			get { return Out(_impl.Destination); }
			set { _impl.Destination = In(value); }
		}
		
		public void Reset( T value )
		{
			_impl.Reset(value);
		}
		
		public void Start()
		{
			_impl.Start();
		}
	}
}