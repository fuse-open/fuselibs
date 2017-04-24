using Uno;
using Uno.Collections;
using Uno.UX;

namespace Fuse.Animations
{
	public interface ITrackProvider { }
	
	//keep actual interface internal
	interface TrackProvider
	{
		double GetDuration(TrackAnimator tas, AnimationVariant variant);
		AnimatorVariant GetAnimatorVariant(TrackAnimator tas);
	}
	
	interface ContinuousTrackProvider : TrackProvider
	{
		SeekResult GetSeekProgress(TrackAnimatorState tas, double progress, double interval, SeekDirection dir,
			out float4 value, out double strength);
		SeekResult GetSeekTime(TrackAnimatorState tas, double elapsed, double interval, SeekDirection dir,
			out float4 value, out double strength);
	}
	
	interface DiscreteTrackProvider : TrackProvider
	{
		SeekResult GetSeekProgress(TrackAnimatorState tas, double progress, double interval, SeekDirection dir,
			out object value, out double strength);
		SeekResult GetSeekTime(TrackAnimatorState tas, double elapsed, double interval, SeekDirection dir,
			out object value, out double strength);
	}
	
	interface KeyframeTrack
	{
		IList<Keyframe> Keyframes { get; }
		KeyframeInterpolation Interpolation { get; set; }
	}

	/** Track animators animate to a specific target value over a fixed duration.
		
		@topic Track animators
		
		The `...Back` parameters implicitly create a backwards timeline. The second timeline has it's own duration, and all properties and then specified in that timeline. This backwards timeline is for all of the animators, not just the ones with a `...Back` property specified. This is important for understanding how the timing works in complex scenarios.
		
		Tracks can be a continuous (like a floating point value), discrete (like an enum value), or a spline track. This is specified implicitly based on the properties used. Note that some properties only have effects with certain track types.

		[subclass Fuse.Animation.TrackAnimator]
	*/
	public abstract class TrackAnimator : Animator
	{
		internal override AnimatorVariant AnimatorVariant 
		{ 
			get 
			{ 
				if (_discreteProvider != null)
					return _discreteProvider.GetAnimatorVariant(this);
				else if (_continuousProvider != null)
					return _continuousProvider.GetAnimatorVariant(this);
				return AnimatorVariant.Allow;
			}
		}
		
		internal override double GetDurationWithDelay(AnimationVariant dir) 
		{ 
			var duration = 0.0;
			if (_discreteProvider != null)
				duration = _discreteProvider.GetDuration(this, dir);
			else if (_continuousProvider != null)
				duration = _continuousProvider.GetDuration(this, dir);
				
			return (dir == AnimationVariant.Backward && HasBack ? DelayBack : Delay) + duration; 
		}

		//if set indicates a discrete provider is being used
		internal TrackProvider _discreteProvider;
		
		bool _isDiscrete;
		internal void MarkDiscrete()
		{
			_discreteProvider = DiscreteSingleTrack.Singleton;
			_continuousProvider = null;
			_isDiscrete = true;
		}
		
		internal TrackProvider _continuousProvider = EasingTrack.Singleton;
		[UXContent]
		public ITrackProvider Provider 
		{ 
			get 
			{ 
				if (_continuousProvider != null)
					return _continuousProvider as ITrackProvider; 
				return null;
			}
			set 
			{ 
				_continuousProvider = null;
				if (value is ContinuousTrackProvider)
					_continuousProvider = value as TrackProvider; 
			}
		}

		internal TrackProvider GetProvider(AnimationVariant variant)
		{
			return _discreteProvider ?? _continuousProvider;
		}
		
		//these properties are usable by the Providers. They are here to make the UX convenient
		//and merge the common ones. Whether they are actually used depends on the provider
		Easing _easing = Fuse.Animations.Easing.Linear;
		/**
			For a continuous track: This specifies the transition easing between a source and target value.
		*/
		[UXContent]
		public Easing Easing 
		{ 
			get { return _easing; }
			set { _easing = value; }
		}
		
		Easing _easingBack;
		bool _hasEasingBack;
		/**
			For a continuous track: This specified the easing for the backward timeline.
		*/
		public Easing EasingBack
		{
			get { return _hasEasingBack ? _easingBack : _easing; }
			set
			{
				_easingBack = value;
				_hasEasingBack = true;
			}
		}
		
		/**
			For a continuous track: The duration of the change of the value.
		*/
		public double Duration { get; set; }
		
		double _durationBack;
		bool _hasDurationBack;
		/** 
			For a continuous track: The duraciton of the change of the value in the backward timeline.
		*/
		public double DurationBack 
		{ 
			get { return _hasDurationBack ? _durationBack : Duration; }
			set
			{
				_durationBack = value;
				_hasDurationBack = true;
			}
		}
		
		double _delayBack;
		bool _hasDelayBack;
		/**
			How long to wait, from the end of the backward timeline, before the animator starts changing the value.
		*/
		public double DelayBack 
		{ 
			get { return _hasDelayBack ? _delayBack : 0; }
			set
			{
				_delayBack = value;
				_hasDelayBack = true;
			}
		}

		internal bool HasBack
		{
			get { return _hasDelayBack || _hasDurationBack || _hasEasingBack; }
		}
		
		KeyframeTrack _keyframeTrack;
		KeyframeTrack KeyframeTrack
		{
			get
			{
				if (_keyframeTrack == null)
				{
					if (_isDiscrete)
					{
						var t = new DiscreteKeyframeTrack();
						_keyframeTrack = t;
						_discreteProvider = t;
					}
					else
					{
						var t = new SplineTrack();
						_keyframeTrack = t;
						_continuousProvider = t;
					}
				}
				return _keyframeTrack;
			}
		}
		
		/** Specifies how the @Keyframes are interpolated. */
		public KeyframeInterpolation KeyframeInterpolation
		{
			get { return KeyframeTrack.Interpolation; }
			set { KeyframeTrack.Interpolation = value; }
		}
		
		[UXContent]
		/** The list of keyframes for this animator.

			@topic Keyframes

			If no keyframes are specified, the animator simply uses the @Easing and @Duration properties to determine
			interpolation between start and end values.

			For the cases where we want to specify several steps for an animation, we can specify keyframes.

			Example:

				<Move RelativeTo="ParentSize">
					<Keyframe X="10" Time="0.5"/>
					<Keyframe X="15" Time="1"/>
					<Keyframe X="5" Time="2"/>
				</Move>

			This @(Move) animator will first animate X to 10 over 0.5 second, then from 10 to 15 over 0.5 second. Finally, it will go from an
			X of 15 to 5 over 1 second.	Here is an example of using @Keyframes with a @Change animator:

				<Page>
					<SolidColor ux:Name="background" Color="#f00"/>
					<ActivatingAnimation>
						<Change Target="background.Color">
							<Keyframe Value="#0f0" TimeDelta="0.25"/>
							<Keyframe Value="#f00" TimeDelta="0.25"/>
							<Keyframe Value="#ff0" TimeDelta="0.25"/>
							<Keyframe Value="#0ff" TimeDelta="0.25"/>
						</Change>
					</ActivatingAnimation>
				</Page>

			This time we use `TimeDelta` instead of time. With `TimeDelta` we can specify time as a relative term instead of absolute. 
			This means that the order of the @Keyframes matter, but it lets us reason about the keyframes in terms of 
			their duration instead of their absolute time on the timeline.
		*/
		public IList<Keyframe> Keyframes
		{
			get { return KeyframeTrack.Keyframes; }
		}

		double _weight = 1;
		/**
			Allows the value set by this animator to be increased or decreased in significance (the default is 1).
			
			This is used for `MixOp="Weight"`. When two animators are active the value of the target attribute will be the weighted average of the applied animators.
		*/
		public double Weight
		{
			get { return _weight; }
			set { _weight = value; }
		}
		
		//source value for actual animation, along with common accessors (used by Easing)
		internal float4 _vectorValue;
		internal object _objectValue;
	}
	

	abstract class TrackAnimatorState : AnimatorState
	{
		internal TrackAnimator Animator;
		ContinuousTrackProvider _continuousProvider;
		DiscreteTrackProvider _discreteProvider;
		
		protected TrackAnimatorState( TrackAnimator animator, CreateStateParams p,
			Visual useVisual = null )
			: base(p, useVisual)
		{
			Animator = animator;
			var pr = animator.GetProvider(Variant);
			_continuousProvider = pr as ContinuousTrackProvider;
			_discreteProvider = pr as DiscreteTrackProvider;
		}
		
		internal override SeekResult SeekProgress(double progress, double interval, SeekDirection dir, 
			double strength )
		{
			if (_continuousProvider != null)
			{
				double oStrength;
				float4 oValue;
				var r = _continuousProvider.GetSeekProgress(this, progress, interval, dir, 
					out oValue, out oStrength );
				SeekValue( oValue, (float)(oStrength * strength * Animator.Weight) );
				return r;
			}
			
			if (_discreteProvider != null)
			{
				double oStrength;
				object oValue;
				var r = _discreteProvider.GetSeekProgress(this, progress, interval, dir, 
					out oValue, out oStrength );
				SeekObjectValue( oValue, (float)(oStrength * strength * Animator.Weight) );
				return r;
			}
			
			return SeekResult.Stable | SeekResult.Complete;
		}
		
		internal override SeekResult SeekTime(double elapsed, double interval, SeekDirection dir,
			double strength )
		{
			double relTime;
			
			if (IsBackward && Animator.HasBack)
				relTime = elapsed - (TotalDuration - Animator.DelayBack - Animator.DurationBack);
			else
				relTime = elapsed - Animator.Delay;
				
			if (_continuousProvider != null)
			{
				double oStrength;
				float4 oValue;
				var r = _continuousProvider.GetSeekTime(this, relTime, interval, dir, 
					out oValue, out oStrength );
				SeekValue( oValue, (float)(oStrength * strength * Animator.Weight) );
				return r;
			}
			
			if (_discreteProvider != null)
			{
				double oStrength;
				object oValue;
				var r = _discreteProvider.GetSeekTime(this, relTime, interval, dir, 
					out oValue, out oStrength );
				SeekObjectValue( oValue, (float)(oStrength * strength * Animator.Weight) );
				return r;
			}
			
			return SeekResult.Stable | SeekResult.Complete;
		}
		
		protected virtual void SeekValue( float4 value, float strength ) { }
		protected virtual void SeekObjectValue( object value, float strength ) { }
		
		public bool IsBackward
		{
			get { return Variant == AnimationVariant.Backward; }
		}
		
		public double Duration
		{
			get { return IsBackward ? Animator.DurationBack : Animator.Duration; }
		}
		
		public Easing Easing
		{
			get { return IsBackward ? Animator.EasingBack : Animator.Easing; }
		}
	}
}