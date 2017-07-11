using Uno;
using Fuse;

namespace Fuse.Motion.Simulation
{
	class ElasticForce<T> : DestinationSimulation<T>
	{
		Fuse.Internal.Blender<T> _blender = Fuse.Internal.BlenderMap.Get<T>();

		static public ElasticForce<T> CreatePoints()
		{
			var a = new ElasticForce<T>(0.01f);
			a.AttractionForce = 200;
			a.AttractionCurve = 0.65f;
			a.Damping = 10;
			a.EnergyEps = 0.05f;
			return a;
		}
		
		static public ElasticForce<T> CreateRadians()
		{
			var a = new ElasticForce<T>(0.01f);
			a.AttractionForce = 200;
			a.Damping = 15;
			a.AttractionCurve = 0.75f;
			a.EnergyEps = 0.01f;
			a.MaxSpeed = 2*Math.PIf;
			return a;
		}
		
		static public ElasticForce<T> CreateNormalized()
		{
			var a = new ElasticForce<T>(0.0001f);
			a.AttractionForce = 50;
			a.Damping = 5;
			a.AttractionCurve = 0.75f;
			a.EnergyEps = 0.0001f;
			a.MaxSpeed = 1.0f;
			return a;
		}
		
		static public ElasticForce<T> CreateUnit( MotionUnit unit )
		{
			switch(unit)
			{
				case MotionUnit.Points: return CreatePoints();
				case MotionUnit.Normalized: return CreateNormalized();
				case MotionUnit.Radians: return CreateRadians();
			}
			throw new Exception( "Unsupported unit type: " +unit );
		}
		
		float _scale;
		const float _zeroTolerance = 1e-05f;
		public ElasticForce( float scale = _zeroTolerance )
		{
			_scale = scale;
		}
		
		public bool IsLocked
		{
			get; 
			set;
		}

		public T Position 
		{ 
			get; 
			set; 
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

		T _attractionDestination;
		public T Destination
		{
			get { return _attractionDestination; }
			set
			{
				_attractionDestination = value;
				_isStatic = false;
			}
		}

		float _attractionForce = 500;
		public float AttractionForce
		{
			get { return _attractionForce; }
			set { _attractionForce = value; }
		}

		float _attractionCurve = 0.65f;
		public float AttractionCurve
		{
			get { return _attractionCurve; }
			set	{ _attractionCurve = value; }
		}

		float _damping = 10f;
		public float Damping
		{
			get { return _damping; }
			set { _damping = value; }
		}

		float _energyEps = 0.01f;//1.0f;
		public float EnergyEps
		{
			get { return _energyEps; }
			set { _energyEps = value;}
		}
		
		float _maxSpeed;
		bool _hasMaxSpeed;
		public float MaxSpeed
		{	
			get { return _maxSpeed; }
			set
			{
				_hasMaxSpeed = true;
				_maxSpeed = value;
			}
		}
		
		public void ResetMaxSpeed()
		{
			_hasMaxSpeed = false;
		}

		bool _isStatic = false;
		public bool IsStatic
		{
			get { return _isStatic; }
			set
			{
				if (_isStatic != value)
				{
					_isStatic = value;
				}
			}
		}

		double timeStep = 0.001;
		
		double _remainTime = 0;
		public void Update(double elapsed)
		{
			_remainTime += elapsed;
			while (_remainTime > 0 && !IsStatic)
			{
				Iterate();
				_remainTime -= timeStep;
			}
			
			if (!IsStatic)
				Velocity = _blender.Weight( Velocity, (float)(1 - Math.Min(1,Damping*elapsed)) );
		}

		T Attraction
		{
			get
			{
				var v = _blender.Sub( Destination, Position );
				double dlength;
				var unit = _blender.ToUnit( v, out dlength );
				float length = (float)dlength;
				
				if (length < _scale)
					return _blender.Zero;
					
				var p = Math.Pow( length, AttractionCurve );
				return _blender.Weight( unit, p );
			}
		}

		float Energy
		{
			get { return (float)(_blender.Length(Attraction) + _blender.Length(Velocity)); }
		}

		void Iterate()
		{
			var acc = _blender.Weight( Attraction, (float)(AttractionForce * timeStep) );
			Velocity = _blender.Add( Velocity, acc );

			if (_hasMaxSpeed)
			{
				double length;
				var unit = _blender.ToUnit( Velocity, out length );
				if (length > _maxSpeed)
					Velocity = _blender.Weight(unit, _maxSpeed);
			}

			if (!IsLocked)
			{ 
				var step = _blender.Weight( Velocity, (float)timeStep );
				Position = _blender.Add( Position, step );

				if (Energy < EnergyEps) 
				{
					Position = Destination;
					IsStatic = true;
				}
			}
		}
		
		public void Reset( T value )
		{
			Position = value;
			Destination = value;
			Velocity = _blender.Zero;
			IsStatic = true;
		}
		
		public void Start()
		{
			//nothing
		}
	}
}
