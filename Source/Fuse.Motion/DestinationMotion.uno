using Uno;
using Uno.UX;
using Fuse.Animations;
using Fuse.Motion.Simulation;

namespace Fuse.Motion
{
	/*
		NOTE: If you add more properties be sure to provide accessors in `MotionConfig` and `Attractor`
	*/
	/**
		This class defines the animation of a value as it moves towards another values. It is typically used as
		a composite object of other types, such as @MotionConfig, @Attract and @Attractor.
	*/
	public class DestinationMotionConfig
	{
		internal MotionDestinationType _type = MotionDestinationType.Elastic;
		bool _explicitType;
		
		/**
			Specifies the basic type of animation for the transition. The meaing of the other properties
			varies depending on this type.
		*/
		public MotionDestinationType Type
		{
			get { return _type; }
			set
			{	
				if (_type == value && !_explicitType)
					return;
					
				_type = value;
				_explicitType = true;
			}
		}
		
		internal Easing _easing = Fuse.Animations.Easing.SinusoidalInOut;
		/**
			For a `Type="Easing"`, this specifies which easing should be used.
		*/
		[UXContent]
		public Easing Easing
		{
			get { return _easing; }
			set
			{
				_easing = value;
				if (!_explicitType)
					_type = MotionDestinationType.Easing;
			}
		}
		
		internal float _duration = 0.5f;
		bool _hasDuration = false;
		
		/**
			Specifies the nominal length of time for a transition. A change in @Distance amount will typically
			take around this amount of time.
			
			For example, a navigation with `Duration=0.3` and `Distance="1"` would take 0.3s to do a single
			page transition.
		*/
		public float Duration
		{
			get { return _duration; }
			set 
			{ 
				_duration = value; 
				_hasDuration = true;
			}
		}

		float _durationExp = 0.5f;
		/**	
			Specifies how much the duration extends depending on the covered distance. This is
			an exponent of that distance `distance ^ DurationExp`: a value of `0` is
			a constant `Duration`, unaffected by distance; a value of `1` is a multple of
			the duration.
		*/
		public float DurationExp
		{
			get { return _durationExp; }
			set { _durationExp = value; }
		}
		
		MotionUnit _unit = MotionUnit.Points;
		/**
			Defines the unit of the animated variable. This is used to establish reasonable defaults and
			apply appropriate multipliers. 
			
			Angular types, `Radians` and `Degrees`, use a wrapping mode, such that 370degrees is
			the same as 10degrees. In this mode there is no guarantee as to what the output value
			will actually be (calling code must also treat equivalent angles the same, or mod them as
			required).
		*/
		public MotionUnit Unit
		{
			get { return _unit; }
			set { _unit = value; }
		}
		
		internal float _distance = 1000;
		bool _hasDistance = false;
		
		/**
			Specifies a reference distance for the motion. This would roughly be considered how much
			distance to cover over `Duration`. Not all simulations interpret the values the same way, so
			it may not be honoured exactly.
			
			Distance is measured as the vector length between the animated property's current value 
			and its target value.
		*/
		public float Distance
		{
			get { return _distance; }
			set 
			{ 
				_distance = value; 
				_hasDistance = true;
			}
		}
		
		internal DestinationSimulation<T> Create<T>()
		{
			var effectiveUnit = Unit;
			var multiplier = 1f;
			if (effectiveUnit == MotionUnit.Degrees)
			{
				effectiveUnit = MotionUnit.Radians;
				multiplier = Math.DegreesToRadians(1);
			}
				
			DestinationSimulation<T> dest;
			
			switch (Type)
			{
				case MotionDestinationType.Easing:
				{
					var q = EasingMotion<T>.CreateUnit(effectiveUnit);
					q.Easing = Easing;
					q.DurationExp = DurationExp;
					if (_hasDuration)
						q.Duration = Duration;
					if (_hasDistance)
						q.NominalDistance = Distance * multiplier;
					dest = q;
					break;
				}
				
				case MotionDestinationType.Elastic:
				{
					var q = ElasticForce<T>.CreateUnit(effectiveUnit);
					dest = q;
					break;
				}
				
				case MotionDestinationType.SmoothSnap:
				{
					var q = SmoothSnap<T>.CreateUnit(effectiveUnit);
					if (_hasDistance)
						q.SpeedDropoutDistance = Distance * multiplier;
					if (_hasDuration)
						q.SetDuration(Duration);
					dest = q;
					break;
				}
				
				default:
				{
					Fuse.Diagnostics.UserError( "Invalidate simulation type: " + Type, this );
					dest = ElasticForce<T>.CreateNormalized();
					break;
				}
			}
			
			if (Unit == MotionUnit.Radians || Unit == MotionUnit.Degrees)
				dest = new AngularAdapter<T>(dest);
				
			if (multiplier != 1)
				dest = new AdapterMultiplier<T>(dest, multiplier);
			
			return dest;
		}
	}
	
	public class DestinationMotion<T> : DestinationMotionConfig
	{
		new internal DestinationSimulation<T> Create()
		{
			return base.Create<T>();
		}
	}
	
}