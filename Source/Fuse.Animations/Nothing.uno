using Uno;

namespace Fuse.Animations
{
	/**
		Allows you to artificially extend the timeline

		All animations for a `Trigger` share a common timeline, which ends when the last animation has completed. In some rare cases, you may want to artificially extend the timeline. This can be done using `Nothing`. Logically, it is a blank animation with a set length, forcing the length of the timeline to be at least the duration of the `Nothing`.
	*/
	public sealed class Nothing : TrackAnimator
	{
		internal override AnimatorState CreateState(CreateStateParams p)
		{
			return new NothingAnimatorState(this, p);
		}
	}
	
	class NothingAnimatorState : TrackAnimatorState
	{
		public NothingAnimatorState( Nothing animator, CreateStateParams p )
			:  base(animator, p)
		{
		}
	}
}
