using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse.Internal;

namespace Fuse.Animations
{
	/**
		Specifies how the spline is interpolated between the keyframes. These options specify how the 
		vertex tangents are calculated and which interpolater to use along the curves.
	*/
	public enum KeyframeInterpolation
	{
		/** The curve is straight between keyframes */
		Linear,
		/** DEPRECATED: Use the name @Smooth instead */
		CatmullRom,
		/** Creates smooth curve that touches all keyframe locations */
		Smooth = CatmullRom,
		/** Custom curve options have been specified. This is set automatically when the options have
			been modified. */
		Custom,
	}
	
	class SplineTrack : ContinuousTrackProvider, ITrackProvider, KeyframeTrack
	{
		List<Keyframe> _frames = new List<Keyframe>();
		[UXContent]
		public IList<Keyframe> Keyframes
		{	
			get { return _frames; }
		}
	
		float _tension = 1; //default for Linear
		/**
			Specifies the Tension in the Kochanek-Bartel spline tangent model.
		*/
		public float Tension 
		{ 
			get { return _tension; } 
			set
			{
				_tension = value;
				_style = KeyframeInterpolation.Custom;
			}
		}
		
		float _bias;
		/**
			Specifies the Bias in the Kochanek-Bartel spline tangent model.
		*/
		public float Bias
		{ 
			get { return _bias; } 
			set
			{
				_bias = value;
				_style = KeyframeInterpolation.Custom;
			}
		}
		
		float _continuity = -1; //default for Linear
		/**
			Specifies the Continuity in the Kochanek-Bartel spline tangent model.
		*/
		public float Continuity
		{ 
			get { return _continuity; } 
			set
			{
				_continuity = value;
				_style = KeyframeInterpolation.Custom;
			}
		}
		
		Curves.PointInterpolater _pointInterpolater = Curves.LinearPoint;
		
		KeyframeInterpolation _style = KeyframeInterpolation.Linear;
		public KeyframeInterpolation Interpolation
		{
			get { return _style; }
			set
			{
				_style = value;
				switch(_style)
				{
					case KeyframeInterpolation.Linear:
						_bias = 0;
						_tension = 1;
						_continuity = -1;
						//is this perhaps an optimization? The CubicHermitePoint should work if the tangets are right
						_pointInterpolater = Curves.LinearPoint;
						break;
						
					case KeyframeInterpolation.CatmullRom:
						_bias = 0;
						_tension = 0;
						_continuity = 0;
						_pointInterpolater = Curves.CubicHermitePoint;
						break;
						
					default:
						_pointInterpolater = Curves.CubicHermitePoint;
						break;
				}
			}
		}
		
		double _duration;
		bool _init;
		void Init()
		{
			if (_init)
				return;
			_duration = Keyframe.CompleteFrames(_frames, Tension, Bias, Continuity);
			_init = true;
		}
		
		double TrackProvider.GetDuration(TrackAnimator ta, AnimationVariant variant)
		{
			Init();
			return _duration;
		}
		
		AnimatorVariant TrackProvider.GetAnimatorVariant(TrackAnimator tas)
		{
			return AnimatorVariant.Allow;
		}
		
		SeekResult ContinuousTrackProvider.GetSeekProgress(TrackAnimatorState tas, double progress, 
			double interval, SeekDirection dir, 
			out float4 value, out double strength)
		{
			return (this as ContinuousTrackProvider).GetSeekTime(tas, progress * _duration, interval, dir,
				out value, out strength );
		}
		
		SeekResult ContinuousTrackProvider.GetSeekTime(TrackAnimatorState tas, double elapsed, double interval, 
			SeekDirection dir, 	
			out float4 value, out double strength)
		{
			Init();
			if (_frames.Count == 0)
			{
				value = float4(0);
				strength = 0;
				return SeekResult.Stable | SeekResult.Complete;
			}

			int segment = 0;
			while (segment < (_frames.Count-1) && _frames[segment].Time <= elapsed)
				++segment;
				
			if (segment == 0)
			{
				var segmentProgress = elapsed / _frames[0].TimeDelta;
				value = _frames[0].Value;
				strength = segmentProgress;
			}
			else
			{
				int previous = segment - 1;
				
				const float zeroTolerance = 1e-05f;
				var segmentProgress = _frames[segment].TimeDelta < zeroTolerance ? 0.0 :
					Math.Clamp( (elapsed - _frames[previous].Time) /  _frames[segment].TimeDelta, 0, 1);
			
				value = _pointInterpolater( _frames[previous].Value, _frames[segment].Value,
					_frames[previous].TangentOut, _frames[segment].TangentIn, (float)segmentProgress );
				strength = 1;
			}

			//debug_log elapsed + ": " + segment + " => " + value + " / " + strength;
			return ( (dir == SeekDirection.Forward ? elapsed >= _duration : elapsed <= 0) ?
				SeekResult.Complete : SeekResult.None) | SeekResult.Stable;
		}
	}
}
