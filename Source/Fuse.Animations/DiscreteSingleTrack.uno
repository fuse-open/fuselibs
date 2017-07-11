using Uno;

namespace Fuse.Animations
{
	class DiscreteSingleTrack : DiscreteTrackProvider, ITrackProvider
	{
		//this provider expected to work as a singleton for TrackAnimator
		public static DiscreteSingleTrack Singleton = new DiscreteSingleTrack();
		
		double TrackProvider.GetDuration(TrackAnimator ta, AnimationVariant variant)
		{
			return variant == AnimationVariant.Backward ? ta.DurationBack : ta.Duration;
		}
		
		AnimatorVariant TrackProvider.GetAnimatorVariant(TrackAnimator ta)
		{
			return ta.HasBack ? AnimatorVariant.HasBackward : AnimatorVariant.Allow;
		}
		
		SeekResult DiscreteTrackProvider.GetSeekProgress(TrackAnimatorState tas, double progress, 
			double interval, SeekDirection dir,
			out object value, out double strength)
		{
			strength = progress;
			value = tas.Animator._objectValue;
			
			return ((dir == SeekDirection.Forward ? progress >= 1 : progress <= 0) ?
				SeekResult.Complete : SeekResult.None) | SeekResult.Stable;
		}
		
		SeekResult DiscreteTrackProvider.GetSeekTime(TrackAnimatorState tas,double elapsed, 
			double interval, SeekDirection dir,
			out object value, out double strength)
		{
			var duration = tas.Duration;
			float progress;
			const float zeroTolerance = 1e-05f;
			if (duration < zeroTolerance)
				progress =
					(dir == SeekDirection.Forward ? 
						elapsed	 >= -zeroTolerance : elapsed > zeroTolerance) ?
						1 : 0;
			else
				progress = (float)(elapsed / duration);
				
			strength = Math.Clamp(progress,0,1);
			value = tas.Animator._objectValue;
			return ((dir == SeekDirection.Forward ? elapsed >= 0 : elapsed <= 0) ?
				SeekResult.Complete : SeekResult.None) | SeekResult.Stable;
		}
	}
}
