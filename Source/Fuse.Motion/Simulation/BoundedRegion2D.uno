using Uno;

using Fuse.Internal;

namespace Fuse.Motion.Simulation
{
	interface BoundedRegion2D : MotionSimulation<float2>
	{
		float2 MaxPosition { get; set; }
		float2 MinPosition { get; set; }
		float2 OverflowExtent { get; set; }
		
		void StartUser();
		void StepUser(float2 offset);
		void EndUser(float2 velocity = float2(0));
		bool IsUser { get; }
		bool IsDestination { get; }
		
		void MoveTo( float2 position );
		float2 Destination { get; }
		
		void Reset(float2 position);
		
		void Adjust(float2 adjust);
	}
	
	/*
		NOTE: Avoid using this class directly since it isn't configurable by the user in any way.
		Instead try to use a `MotionConfig` sub-type that allows configuration.
	*/
	class BasicBoundedRegion2D : BoundedRegion2D
	{
		const float _zeroTolerance = 1e-05f;

		static public BasicBoundedRegion2D CreatePoints()
		{
			var region = new BasicBoundedRegion2D();
			var dest = ElasticForce<float2>.CreatePoints();
			region._destination = dest;
			return region;
		}
		
		static public BasicBoundedRegion2D CreateExponential()
		{
			var region = new BasicBoundedRegion2D();
			region._destination = ElasticForce<float2>.CreateNormalized();
			region._snap = SmoothSnap<float2>.CreateNormalized();
			region._overflowExtent = float2(0.5f);
			return region;
		}
		
		static public BasicBoundedRegion2D CreateRadians()
		{
			var region = new BasicBoundedRegion2D();
			region._destination = ElasticForce<float2>.CreateRadians();
			region._snap = SmoothSnap<float2>.CreateRadians();
			region._overflowExtent = float2(0.3f);
			return region;
		}
		
		internal BasicBoundedRegion2D()
		{
		}

		public void Reset(float2 position)
		{
			_destination.Reset(position);
			_snap.Reset(position);
			_moveMode = MoveMode.Stop;
		}
		
		enum MoveMode
		{
			Stop,
			User,
			Friction,
			Snap,
			Destination,
		}
		MoveMode _moveMode = MoveMode.Stop;

		float2 _maxPosition = float2(float.PositiveInfinity);
		public float2 MaxPosition 
		{ 
			get { return _maxPosition; }
			set 
			{
				if (_maxPosition == value)
					return;
				
				_maxPosition = value; 
				if (_moveMode == MoveMode.Destination)
					_destination.Destination = Math.Clamp( _destination.Destination, MinPosition, MaxPosition );
			}
		}
		
		float2 _minPosition = float2(float.NegativeInfinity);
		public float2 MinPosition 
		{ 
			get { return _minPosition; }
			set { _minPosition = value; }
		}
		
		float2 _overflowExtent = float2(150);
		public float2 OverflowExtent 
		{
			get { return _overflowExtent; }
			set { _overflowExtent = value; }
		}
		
		public void StartUser()
		{
			_moveMode = MoveMode.User;
		}
		
		public void StepUser(float2 inOffset)
		{
			Position = SnapPosition( Position, inOffset + Position );
		}
		
		public void EndUser(float2 velocity = float2(0))
		{
			if (!IsUser)
				return;
			_velocity = SnapVelocity( Position, velocity );
			_moveMode = MoveMode.Friction;
		}
		
		public bool IsUser
		{
			get { return _moveMode == MoveMode.User; }
		}
		
		public bool IsDestination
		{
			get { return _moveMode == MoveMode.Destination; }
		}
		
		public float2 Position { get; set; }
		DestinationSimulation<float2> _destination;
		
		internal DestinationSimulation<float2> DestinationSimulation
		{
			get { return _destination; }
			set { _destination = value; }
		}
		
		public void Adjust(float2 adjust)
		{
			if (adjust == float2(0)) //exact to avoid 0-update scenario
				return;
				
			if (_moveMode == MoveMode.User)
				return;
				
			Position += adjust;
			
			switch (_moveMode) 
			{
				case MoveMode.User:
				case MoveMode.Stop:
					break;
					
				case MoveMode.Destination:
					MoveTo( Destination + adjust );
					break;
					
				//It's unsure what to do in the other modes still...
			}
		}
		
		public void MoveTo( float2 target )
		{	
			_destination.Destination = Math.Clamp( target, MinPosition, MaxPosition );
			_destination.Position = Position;
			_destination.Velocity = Velocity;
			_destination.Start();
			_moveMode = MoveMode.Destination;
		}
		
		public float2 Destination
		{
			get { return _destination.Destination; }
		}
		
		public bool IsStatic
		{
			get { return _moveMode == MoveMode.Stop || _moveMode == MoveMode.User; }
		}
		
		public void Update(double elapsed)
		{
			switch (_moveMode)
			{
				case MoveMode.Stop:
				case MoveMode.User:
					return;
					
				case MoveMode.Friction:
					MoveFriction(elapsed);
					break;
				
				case MoveMode.Snap:
					if (MoveSnap(elapsed))
						_moveMode = MoveMode.Stop;
					break;
					
				case MoveMode.Destination:
					MoveDestination(elapsed);
					break;
			}
		}
		
		float2 _velocity;
		public float2 Velocity
		{
			get { return _velocity; }
			set
			{
				_velocity = value;
				if (_moveMode == MoveMode.Stop)
					_moveMode = MoveMode.Friction;
			}
		}
		
		MotionSimulation<float2> _friction = Friction<float2>.CreatePoints();
		internal MotionSimulation<float2> FrictionSimulation
		{
			get { return _friction; }
			set { _friction = value; }
		}
		void MoveFriction(double elapsed)
		{
			_friction.Velocity = _velocity;
			_friction.Position = Position;
			
			_friction.Update( elapsed );
			SnapSetPositionVelocity(_friction.Position, _friction.Velocity);
			
			if (_friction.IsStatic)
			{
				_moveMode = MoveMode.Snap;
				return;
			}
			
			//allow one axis to snap while other is still moving
			MoveSnap( elapsed, 
				Math.Abs(_velocity.X) < _zeroTolerance,
				Math.Abs(_velocity.Y) < _zeroTolerance );
		}
		
		void SnapSetPositionVelocity( float2 nextPosition, float2 nextVelocity )
		{
			//clamp based on expected position, to ensure it clamps in the end zones
			Velocity = SnapVelocity(nextPosition, nextVelocity);
			Position = SnapPosition(Position, nextPosition);
		}
		
		float2 SnapPosition( float2 prev, float2 next )
		{
			switch (Overflow)
			{
				case OverflowType.Open:
					return next;
					
				case OverflowType.Clamp:
					return Math.Clamp(next, MinPosition, MaxPosition);
					
				case OverflowType.Elastic:
				{
					var over = CalcOver( next );
					if (Math.Abs(over.X) + Math.Abs(over.Y) < _zeroTolerance)
						return next;
					
					//TODO: this doesn't correctly account for the step when next moves into the
					//overflow, clipping it prematurely
					var diff = next - prev;
					var f = Math.Clamp( float2(1) - Math.Abs(over) / _overflowExtent, float2(0), float2(1) );
					var mod = prev + diff * f;
					
					//in case we're moving out of the snap area don't modify it
					var modOver = CalcOver(mod);
					if (Math.Abs(next.X) < Math.Abs(modOver.X))
						mod.X = next.X;
					if (Math.Abs(next.Y) < Math.Abs(modOver.Y))
						mod.Y = next.Y;
					return mod;
				}
			}
			
			return next;
		}
		
		float2 SnapVelocity( float2 position, float2 v )
		{
			var over = CalcOver( position );
			if (Math.Abs(over.X) + Math.Abs(over.Y) < _zeroTolerance)
				return v;
			
			switch (Overflow)
			{
				case OverflowType.Open:
					return v;
					
				case OverflowType.Clamp:
				{
					if (over.X != 0)
						v.X = 0;
					if (over.Y != 0)
						v.Y = 0;
					return v;
				}
					
				case OverflowType.Elastic:
				{
					var f = Math.Clamp( float2(1) - Math.Abs(over) / _overflowExtent, float2(0), float2(1) );
					var mod = v * f;
					if (Math.Sign(v.X) != Math.Sign(over.X))
						mod.X = v.X;
					if (Math.Sign(v.Y) != Math.Sign(over.Y))
						mod.Y = v.Y;
						
					return mod;
				}
			}
			
			return v;
		}
		
		
		DestinationSimulation<float2> _snap = SmoothSnap<float2>.CreatePoints();
		
		internal DestinationSimulation<float2> SnapSimulation
		{
			get { return _snap; }
			set { _snap = value; }
		}
		
		bool MoveSnap( double elapsed, bool X = true, bool Y = true )
		{
			var over = CalcOver( Position );
			var off = Vector.Length(over);
			if (off <= 0)
				return true;
			
			_snap.Position = Position;
			_snap.Velocity = Velocity;
			_snap.Destination = Position - over;
			
			_snap.Update(elapsed);
			
			Position = _snap.Position;
			var nv = Velocity;
			var np = Position;
			
			if (X)
			{
				nv.X = _snap.Velocity.X;
				np.X = _snap.Position.X;
			}
			if (Y)
			{
				nv.Y = _snap.Velocity.Y;
				np.Y = _snap.Position.Y;
			}
			
			Velocity = nv;
			Position = np;
			
			return _snap.IsStatic;
		}
		
		void MoveDestination(double elapsed)
		{
			_destination.Position = Position;
			_destination.Velocity = Velocity;
			
			_destination.Update(elapsed);

			SnapSetPositionVelocity(_destination.Position, _destination.Velocity);
				
			if (_destination.IsStatic)
				_moveMode = MoveMode.Stop;
		}
		
		float2 CalcOver( float2 sp )
		{
			var min = MinPosition;
			var max = MaxPosition;
			var over = float2(0);
			if (sp.X < min.X)
				over.X = sp.X - min.X;
			else if (sp.X > max.X)
				over.X = sp.X - max.X;
				
			if (sp.Y < min.Y)
				over.Y = sp.Y - min.Y;
			else if (sp.Y > max.Y)
				over.Y = sp.Y - max.Y;
				
			return over;
		}
	
		OverflowType _overflow = OverflowType.Elastic;
		public OverflowType Overflow
		{
			get { return _overflow; }
			set { _overflow = value; }
		}
	}
}
