using Uno;
using Uno.UX;

using Fuse;
using Fuse.Motion;
using Fuse.Motion.Simulation;

namespace Fuse.Animations
{
	[UXAutoGeneric("Attractor", "Target")]
	/** Animates a property to a target value using a physics-like attraction simulation.

	 	Instead of animating a property directly, an attractors act as an intermediary between an animator 
	 	and its target. It will continuously animate its target towards its `Value` using a simple form 
	 	of physics simulation. We can combine this behavior with animation by animating the attractor's `Value` property.

			<Panel ux:Name="somePanel">
				<Translation ux:Name="someTranslation"/>
				<Attractor ux:Name="someAttractor" Target="someTranslation.X"/>
				<WhilePressed>
					<Change someAttractor.Value="100"/>
				</WhilePressed>

			</Panel>
	*/
	public class Attractor<T> : Behavior, IPropertyListener
	{
		internal Attractor() { }

		/**	The property to be animated.
			@ux-property 
		*/
		public Property<T> Target { get; private set; }

		[UXConstructor]
		public Attractor([UXParameter("Target")] Property<T> target)
		{
			if (target == null)
				throw new ArgumentNullException(nameof(target));

			Target = target;
		}

		DestinationMotion<T> _motion = new DestinationMotion<T>();
		/** Can be used to override the object that will compute the animation. */
		public DestinationMotion<T> Motion
		{
			get { return _motion; }
			set 
			{ 
				_motion = value;
				if (IsRootingCompleted)
					Fuse.Diagnostics.UserError( "Motion should not be changed post-rooting", this );
			}
		}
		
		/** Specifies the basic type of animation for the transition. The meaing of the other properties
			varies depending on this type. */
		public MotionDestinationType Type
		{
			get { return _motion.Type; }
			set { _motion.Type = value; }
		}
		
		/** For a `Type="Easing"`, this specifies which easing should be used.	*/
		[UXContent]
		public Easing Easing
		{
			get { return _motion.Easing; }
			set { _motion.Easing = value; }
		}
		
		/**
			Specifies the nominal length of time for a transition. A change in @Distance amount will typically
			take around this amount of time.
			
			For example, a navigation with `Duration=0.3` and `Distance="1"` would take 0.3s to do a single
			page transition.
		*/
		public float Duration
		{
			get { return _motion.Duration; }
			set { _motion.Duration = value; }
		}
		
		public float DurationExp
		{
			get { return _motion.DurationExp; }
			set { _motion.DurationExp = value; }
		}
		
		public float Distance
		{
			get { return _motion.Distance; }
			set { _motion.Distance = value; }
		}

		/**
			The unit being used for the animation.
		*/
		public MotionUnit Unit
		{
			get { return _motion.Unit; }
			set { _motion.Unit = value; }
		}
		///////// End Motion Properties
		
		DestinationSimulation<T> _sim;
		
		bool _isEnabled = true;
		public bool IsEnabled
		{
			get { return _isEnabled; }
			set
			{
				if (_isEnabled == value)
					return;
				_isEnabled = true;
				if (!_isEnabled && _sim != null)
					_sim.Reset( Target.Get() );
				CheckNeedUpdate();
			}
		}

		float _timeMultiplier = 1;
		public float TimeMultiplier
		{
			get { return _timeMultiplier; }
			set { _timeMultiplier = value; }
		}

		public T Value
		{
			get 
			{ 
				if (IsRootingCompleted)
					return _sim.Destination;
				return Target.Get();
			}
			set
			{
				if (IsRootingCompleted)
				{
					_sim.Destination = value;
					CheckNeedUpdate();
				}
				else 
				{
					Target.Set( value, this );
				}
			}
		}
		
		bool _isUpdate;
		void CheckNeedUpdate()
		{
			var need = _sim != null && !_sim.IsStatic;
			if (need == _isUpdate)
				return;
				
			if (need)
				UpdateManager.AddAction(Update);
			else
				UpdateManager.RemoveAction(Update);
			_isUpdate = need;
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			_sim = Motion.Create();
			_sim.Reset( Target.Get() );
			Target.AddListener(this);
		}

		protected override void OnUnrooted()
		{
			_sim = null;
			CheckNeedUpdate();
			Target.RemoveListener(this);
			base.OnUnrooted();
		}

		void Update()
		{
			if (_sim != null)
			{
				_sim.Update(Time.FrameInterval * _timeMultiplier);
				Target.Set(_sim.Position, this);
			}
			CheckNeedUpdate();
		}
		
		void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector prop)
		{
			if (_sim == null) return;
			
			var val = Target.Get();

			if (!IsEnabled || _sim.IsStatic)
				_sim.Reset( val );
			else
				_sim.Position = val;
				
			CheckNeedUpdate();
		}
	}
}
