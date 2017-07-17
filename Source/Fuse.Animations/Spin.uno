using Uno;

namespace Fuse.Animations
{
	/**
		Continuously rotates an element, given a `Frequency` measured in full rotations per second.

			<Panel>
			<WhilePressed>
				<Spin Frequency="2" />
			</WhilePressed>
			</Panel>

		As with @(Cycle), you may also specify a `Duration` to control the length of the animation.

		@mount Animation
	*/
	public sealed class Spin : OpenAnimator
	{
		public Spin()
		{
			MixOp = MixOp.Add;
		}

		/**
			Specifies an alternate target for the spin (the default is the parent of the trigger).
		*/
		public Visual Target { get; set; }

		double _hertz = 1;
		/**
			The frequency of the spinnging, measured in Hertz (how many full rotations per second).
		*/
		public double Frequency
		{
			get { return _hertz; }
			set { _hertz = value; }
		}

		internal override AnimatorState CreateState(CreateStateParams p)
		{
			return new SpinState(this, p);
		}
	}

	//TODO: share some of this with TransformAnimatorState somehow?
	class SpinState : OpenAnimatorState
	{
		Spin Animator;
		IMixerHandle<Transform> mixHandle;
		Rotation transform = new Rotation();

		public SpinState( Spin animator, CreateStateParams p )
			: base(animator, p, animator.Target )
		{
			this.Animator = animator;
			mixHandle = Animator.Mixer.RegisterTransform(Visual, Animator.MixOp, TransformPriority.Rotate);
		}

		double degrees;

		public override void Disable()
		{
			if (mixHandle == null)
				return;
				
			degrees = 0;
			mixHandle.Unregister();
			mixHandle = null;
		}

		protected override bool Seek(bool on, float interval, float strength, SeekDirection dir)
		{
			if (mixHandle == null || transform == null)
			{
				debug_log "Invalid seek";
				return true;
			}

			//same logic as in cycle (TODO: merge into generic form)
			bool done = false;
			var oldDegrees = degrees;
			degrees = degrees + interval * 360 * Animator.Frequency;
			const float zeroTolerance = 1e-05f;
			if (on)
			{
				degrees = Math.Mod( degrees, 360 );
			}
			else if(oldDegrees <= zeroTolerance || degrees <= zeroTolerance ||
				oldDegrees >= (360-zeroTolerance) || degrees >= (360-zeroTolerance) )
			{
				degrees = 0;
				done = true;
			}

			transform.Degrees = (float)degrees;
			mixHandle.Set( transform, strength );
			return done;
		}
	}
}
