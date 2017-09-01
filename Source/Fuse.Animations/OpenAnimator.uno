using Uno;

namespace Fuse.Animations
{
	/** Open animators animate repeatedly for as long as the trigger is active.
		
		The `Duration` and `Delay` specify when this animator is "on". This is the time when the animator will be actively applying its effect. Outside of this period the animator is "off".  When off the animator will continue playing until it reaches a suitable resting value. This prevents the animation from jerking between values.
		
		@topic Open animators

		## Available open animators
		[subclass Fuse.Animation.OpenAnimator]
	*/
	public abstract class OpenAnimator : Animator
	{
		internal override AnimatorVariant AnimatorVariant
		{
			get { return AnimatorVariant.Disallow; }
		}
		
		double _duration;
		/** 
			Specifies how long the animator is "on". 
		
			If the OpenAnimator does not have a duration (the default) it will be "on" after the `Delay` is reached, and continue to be "on" when the end of the timeline is reached.
		*/
		public double Duration 
		{ 
			get { return _duration; }
			set
			{
				_duration = value;
				_hasDuration = true;
			}
		}
		
		public void ResetDuration()
		{
			_duration = 0;
			_hasDuration = false;
		}
		
		bool _hasDuration = false;
		public bool HasDuration { get { return _hasDuration; } }

		internal override double GetDurationWithDelay(AnimationVariant dir)
		{
			return Delay + Duration;
		}
		
		internal double GetDelay(AnimationVariant dir, double totalDuration )
		{
			return Delay;
		}
	}

	abstract class OpenAnimatorState : AnimatorState
	{
		OpenAnimator Animator;
		bool _seekDone = true;
		
		protected OpenAnimatorState( OpenAnimator animator, CreateStateParams p, 
			Visual useVisual = null )
			: base(p, useVisual) 
		{ 
			Animator = animator;
		}
			
		public override bool IsOpenEnd { get { return true; } }
		
		internal override SeekResult SeekProgress(double progress, double interval, SeekDirection dir, 
			double strength)
		{
			return SeekTime( progress * TotalDuration, interval, dir, strength );
		}
		
		internal override SeekResult SeekTime(double nominal, double interval, SeekDirection dir,
			double strength )
		{
			var delay = Animator.GetDelay(Variant, TotalDuration);
			const float zeroTolerance = 1e-05f;
			var on = dir == SeekDirection.Forward ? nominal > (delay - zeroTolerance) :
				nominal > (delay + zeroTolerance);
	
			if (Animator.HasDuration && nominal > (delay + Animator.Duration - zeroTolerance))
				on = false;
	
			var mayEnd = dir == SeekDirection.Forward ?
				nominal >= (Animator.GetDurationWithDelay(Variant) - zeroTolerance) :
				nominal <= (delay + zeroTolerance);
			
			//this would require knowing that we actually seeked "interval" length, which isn't always
			//true during progress seeking
			//if ( (nominal - interval) < delay && dir == SeekDirection.Forward)
			//	interval = nominal - delay;
			
			//shortcut if nothing is to be done
			if (on || !_seekDone)
				_seekDone = Seek( on, (float)interval, (float)strength, dir );
				
			return (_seekDone ? SeekResult.Stable : SeekResult.None) |
				(mayEnd && _seekDone ? SeekResult.Complete : SeekResult.None);
		}
		
		protected abstract bool Seek(bool on, float interval, float strength, SeekDirection dir);
	}
	
}
