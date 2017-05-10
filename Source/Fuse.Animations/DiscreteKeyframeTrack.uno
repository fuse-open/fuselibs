using Uno;
using Uno.Collections;
using Uno.UX;

namespace Fuse.Animations
{
	class DiscreteKeyframeTrack : DiscreteTrackProvider, ITrackProvider, KeyframeTrack
	{
		List<Keyframe> _frames = new List<Keyframe>();
		[UXContent]
		public IList<Keyframe> Keyframes
		{
			get { return _frames; }
		}
		
		public KeyframeInterpolation Interpolation { get; set; }
		
		double _duration;
		bool _init;
		void Init()
		{
			if (_init)
				return;
			
			_duration = Keyframe.CompleteFrames(_frames, 0,0,0);
			_init = true;
		}
		
		double TrackProvider.GetDuration(TrackAnimator ta, AnimationVariant variant)
		{
			Init();
			return _duration;
		}
		
		AnimatorVariant TrackProvider.GetAnimatorVariant(TrackAnimator ta)
		{
			return AnimatorVariant.Allow;
		}
		
		SeekResult DiscreteTrackProvider.GetSeekProgress(TrackAnimatorState tas, double progress, 
			double interval, SeekDirection dir,
			out object value, out double strength)
		{
			return (this as DiscreteTrackProvider).GetSeekTime(tas, progress * _duration, interval, dir,
				out value, out strength );
		}
		
		SeekResult DiscreteTrackProvider.GetSeekTime(TrackAnimatorState tas,double elapsed, 
			double interval, SeekDirection dir,
			out object value, out double strength)
		{
			Init();
			if (_frames.Count == 0)
			{
				value = null;
				strength = 0;
				return SeekResult.Complete | SeekResult.Stable;
			}
			
			int segment = -1;
			while (segment < (_frames.Count-2) && _frames[segment+1].Time <= elapsed)
				++segment;

			if (segment == -1)
			{
				value = _frames[0].ObjectValue;
				strength = 0;
			}
			else
			{
				value = _frames[segment].ObjectValue;
				strength = 1;
			}
			
			return ((dir == SeekDirection.Forward ? elapsed >= 0 : elapsed <= 0) ? 
				SeekResult.Complete : SeekResult.None) | SeekResult.Stable;
		}
	}
}
