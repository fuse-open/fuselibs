using Uno;

namespace Fuse.Animations
{
	class EasingTrack : ContinuousTrackProvider, ITrackProvider
	{
		//this provider expected to work as a singleton for TrackAnimator
		public static EasingTrack Singleton = new EasingTrack();
		
		double TrackProvider.GetDuration(TrackAnimator ta, AnimationVariant variant)
		{
			return (variant == AnimationVariant.Backward && ta.HasBack) ? ta.DurationBack : ta.Duration;
		}
		
		AnimatorVariant TrackProvider.GetAnimatorVariant(TrackAnimator ta)
		{
			return ta.HasBack ? AnimatorVariant.HasBackward : AnimatorVariant.Allow;
		}
		
		SeekResult ContinuousTrackProvider.GetSeekProgress(TrackAnimatorState tas, double progress, 
			double interval, SeekDirection dir,
			out float4 value, out double strength)
		{
			progress = Math.Clamp( progress, 0, 1 );
			var ease = tas.Easing.Map((float)progress);
			
			strength = ease;
			value = tas.Animator._vectorValue;
			
			return ( (dir == SeekDirection.Forward ? progress >= 1 : progress <= 0) ?
				SeekResult.Complete : SeekResult.None) | SeekResult.Stable;
		}
		
		SeekResult ContinuousTrackProvider.GetSeekTime(TrackAnimatorState tas,double elapsed, double interval, SeekDirection dir,
			out float4 value, out double strength)
		{
			var duration = tas.Duration;
			float progress;
			const float zeroTolerance = 1e-05f;
			if (duration < zeroTolerance)
				progress =
					(dir == SeekDirection.Forward ? 
						elapsed >= -zeroTolerance : elapsed > zeroTolerance) ?
						1 : 0;
			else
				progress = (float)(elapsed / duration);
				
			return (this as ContinuousTrackProvider).GetSeekProgress(tas, progress, interval, dir, out value, out strength );
		}
	}
}
