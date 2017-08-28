using Uno;
using Uno.UX;
using Uno.Collections;
using Fuse;

namespace Fuse.Animations
{
	public enum AnimationVariant
	{
		Forward,
		Backward
	}
	
	public enum PlayMode
	{
		Once,
		Wrap,
	}

	/**
		Defines the animation used by a @Trigger.
		
		A @Trigger has an implicit `TriggerAnimation`; you can add animators directly to the trigger. Using a `TriggerAnimation` is typically only used if a different backwards animation is required that cannot be achieved using the various `...Back` properties of the @Animator.
	*/
	public class TriggerAnimation
	{
		List<Animator> _animators;
		[UXContent]
		public IList<Animator> Animators
		{
			get
			{
				if (_animators == null) _animators = new List<Animator>();
				return _animators;
			}
		}
		
		public bool HasAnimators
		{
			get { return _animators != null && _animators.Count > 0; }
		}

		internal TriggerAnimation _backward;
		public TriggerAnimation Backward
		{
			get
			{
				if (_backward == null)
					_backward = new TriggerAnimation();
				return _backward;
			}
			set
			{
				_backward = value;
			}
		}
		
		public bool HasBackward
		{
			get { return _backward != null; }
		}
		
		internal AnimatorState[] CreateAnimatorsState(AnimationVariant variant, Visual elm)
		{
			var csp = new CreateStateParams{
				Variant = variant,
				TotalDuration = GetAnimatorsDuration(variant),
				Attached = elm };
			if (_animators == null)
				return new AnimatorState[0];
				
			var state = new AnimatorState[_animators.Count];
			for( int i=0; i < _animators.Count; ++i )
				state[i] = _animators[i].CreateState(csp);
			return state;
		}
		
		public double GetAnimatorsDuration(AnimationVariant variant)
		{
			if (variant == AnimationVariant.Backward && _backward != null)
				return _backward.GetAnimatorsDuration(AnimationVariant.Forward);
				
			if (_animators == null) 
				return 0.0;

			var max = 0.0;
			var c = _animators.Count;
			for (int i=0; i < c; ++i)
			{
				var q = _animators[i].GetDurationWithDelay(variant);
				max = Math.Max(max, q);
			}

			return max;
		}
		
		double _timeMultiplier = 1;
		public double TimeMultiplier
		{
			get { return _timeMultiplier; }
			set 
			{ 
				if (_timeMultiplier == value)
					return;
				_timeMultiplier = value; 
				OnTimeChanged();
			}
		}
		
		bool _hasStretchDuration;
		double _stretchDuration;
		public double StretchDuration
		{
			get { return _stretchDuration; }
			set
			{
				if (_stretchDuration == value && _hasStretchDuration)
					return;
				_stretchDuration = value;
				_hasStretchDuration = true;
				OnTimeChanged();
			}
		}
		
		double _crossFadeDuration = 0.5;
		public double CrossFadeDuration
		{
			get { return _crossFadeDuration; }
			set { _crossFadeDuration = value; }
		}
		
		void OnTimeChanged()
		{
			if (TimeChanged != null)
				TimeChanged();
		}
		
		public double GetTimeMultiplier(AnimationVariant variant)
		{
			if (_hasStretchDuration)
			{
				var dur = GetAnimatorsDuration(variant);
				const float zeroTolerance = 1e-05f;
				if (_stretchDuration < zeroTolerance)
					return 1;
					
				var mult = dur / _stretchDuration * TimeMultiplier;
				return mult;
			}
			
			return TimeMultiplier;
		}
		
		internal event Action TimeChanged;
		
		internal bool HasDirectionVariant
		{
			get 
			{
				if (_animators == null)
					return false;
					
				bool has = false;
				var c = _animators.Count;
				for (int i=0; i < c; ++i)
				{
					var v = _animators[i].AnimatorVariant;
					if (v == AnimatorVariant.HasBackward)
						has = true;
					if (v == AnimatorVariant.Disallow)
						return false;
				}
				
				return has;
			}
		}
		
		internal TriggerAnimationState CreateState(Visual elm = null)
		{
			return new TriggerAnimationState(this, elm);
		}

		internal AnimationVariant RestrictVariant( AnimationVariant variant )
		{
			if (!HasDirectionVariant && _backward == null)
				return AnimationVariant.Forward;
			return variant;
		}
		
		internal Player CreatePlayer(Visual node = null, AnimationVariant variant = AnimationVariant.Forward)
		{
			variant = RestrictVariant(variant);
				
			if (variant == AnimationVariant.Forward)
				return new Player(node, this, AnimationVariant.Forward, PlayMode);
			
			if (_backward != null)
				return new Player(node, _backward, AnimationVariant.Forward, PlayMode);
				
			return new Player(node, this, AnimationVariant.Backward, PlayMode);
		}
		
		PlayMode _playMode = PlayMode.Once;
		public PlayMode PlayMode
		{
			get { return _playMode; }
			set { _playMode = value; }
		}
	}
	
	[Flags]
	enum PlayerFeedbackFlags
	{
		None = 0,
		Wrapped = 1 << 0,
		Animated = 1 << 1,
	}
	
	interface IBasePlayerFeedback
	{
		void OnPlaybackDone(object s);
		void OnStable(object s);
	}

	interface IPlayerFeedback : IBasePlayerFeedback
	{
		void OnProgressUpdated(object s, PlayerFeedbackFlags flags);
	}
	
	interface IUnwrappedPlayerFeedback : IBasePlayerFeedback
	{
		/**
			flags will never contain Wrapped. The TriggerAnimation takes care of unwrapping
			the values and presenting everything strictly as prev => next values.
			
			If there is no elapsed time it will not be sent.
		*/
		void OnProgressUpdated(object s, double prev, double next, PlayerFeedbackFlags flags);
	}
	
	class TriggerAnimationState : IPlayerFeedback
	{
		TriggerAnimation Animation { get; private set; }
		Visual _node;
		
		internal TriggerAnimationState( TriggerAnimation animation, Visual node )
		{ 
			Animation = animation;
			Animation.TimeChanged += OnTimeChanged;
			_node = node;
		}
		
		Player _forePlayer, _backPlayer, _curPlayer;
		//this may not match _curPlayer.Variant due to overrides
		AnimationVariant _curPlayerVariant;

		public void Dispose()
		{
			Animation.TimeChanged -= OnTimeChanged;
			Feedback = null;
			
			if (_forePlayer != null)
			{
				_forePlayer.Disable();
				_forePlayer = null;
			}
			
			if (_backPlayer != null)
			{
				_backPlayer.Disable();
				_backPlayer = null;
			}
			
			_curPlayer = null;
			_node = null;
		}
		
		void OnTimeChanged()
		{
			if (_forePlayer != null)
				_forePlayer.TimeChanged();
			if (_backPlayer != null)
				_backPlayer.TimeChanged();
		}
		
		public IUnwrappedPlayerFeedback Feedback;
		void TrackProgress( Player player )
		{
			player.Feedback = this;
		}
		
		double _prevProgress;
		void IPlayerFeedback.OnProgressUpdated(object s, PlayerFeedbackFlags flags)
		{
			if (s != _curPlayer)
				return;
				
			if (Feedback != null)
			{
				var prev = _prevProgress;
				var cur = Progress;
				var diff = cur - prev;
				
				if (diff == 0) //yes, exact (nothing happened, double-update in frame)
					return;
				
				if (flags.HasFlag(PlayerFeedbackFlags.Wrapped))
				{
					flags &= ~PlayerFeedbackFlags.Wrapped;
					Feedback.OnProgressUpdated(this, prev, diff > 0 ? 0 : 1, flags);
					Feedback.OnProgressUpdated(this, diff > 0 ? 1 : 0, cur, flags);
				}
				else
				{
					Feedback.OnProgressUpdated(this, prev, cur, flags);
				}
			}

			_prevProgress = Progress;
		}
		
		void IBasePlayerFeedback.OnPlaybackDone(object s)
		{
			if (s != _curPlayer)
				return;
				
			if (Feedback != null)
				Feedback.OnPlaybackDone(this);
		}

		void IBasePlayerFeedback.OnStable(object s)
		{
			if (s != _curPlayer)
				return;

			if (Feedback != null)
				Feedback.OnStable(this);
		}

		public bool IsStable
		{
			get
			{
				if (_curPlayer == null)
					return true;
				return _curPlayer.IsStable;
			}
		}
		
		Player GetPlayer(AnimationVariant variant = AnimationVariant.Forward, bool noFade = false)
		{
			Player cur, prev;
			
			variant = Animation.RestrictVariant(variant);
			
			if (_curPlayer != null && _curPlayerVariant == variant)
				return _curPlayer;
			
			bool isNew = false;
			if (variant == AnimationVariant.Forward)
			{
				if (_forePlayer == null)
				{
					_forePlayer = Animation.CreatePlayer(_node,variant);
					isNew = true;
				}
			
				cur = _forePlayer;
				prev = _backPlayer;
			}
			else
			{
				if (_backPlayer == null)
				{
					_backPlayer = Animation.CreatePlayer(_node,variant);
					_backPlayer.SeekProgress(1, false);
					isNew = true;
				}

				cur = _backPlayer;
				prev = _forePlayer;
			}
			
			if (isNew)
				TrackProgress(cur);
			
			//set prior to switching so any callbacks generated reflect our new current player
			_curPlayer = cur;
			_curPlayerVariant = variant;
			
			if (prev != null)
			{
				var prevProgress = prev.Progress;
				
				prev.SeekProgress( prevProgress, false ); //stops progression
				cur.SeekProgress(prevProgress, false);

				if (isNew)
					cur.Strength = 0;
					
				var remainTime = prev.RemainTime;
				const float zeroTolerance = 1e-05f;
				if (prev.IsSyncState || remainTime < zeroTolerance || noFade)
				{
					prev.Strength = 0;
					cur.Strength = 1;
				}
				else
				{
					var fadeTime = Math.Min( remainTime, Animation.CrossFadeDuration );
					cur.FadeIn(fadeTime);
					prev.FadeOut( fadeTime );
				}
			}
			
			return cur;
		}
		
		public void PlayOff()
		{
			var p = GetPlayer(AnimationVariant.Backward);
			p.PlayToStart();
		}
		
		public void PlayOn()
		{
			var p = GetPlayer(AnimationVariant.Forward);
			p.PlayToEnd();
		}
		
		public void PlayEnd( bool on )
		{
			if (on)
				PlayOn();
			else
				PlayOff();
		}
		
		public double Progress
		{
			get
			{
				if (_curPlayer != null)
					return _curPlayer.Progress;
				return 0;
			}
		}
		
		public double PreviousProgress
		{
			get
			{
				return _prevProgress;
			}
		}
		
		public double CurrentAnimatorsDuration
		{
			get
			{
				if (_curPlayer == null)
					return Animation.GetAnimatorsDuration( AnimationVariant.Forward );
				return _curPlayer.AnimatorsDuration;
			}
		}
		
		public bool ProgressFullOn { get { return Progress >= 1; } }
		public bool ProgressFullOff { get { return Progress <= 0; } }
		
		Player GetCurrentPlayer( AnimationVariant tendTo, SeekFlags flags )
		{
			if (!flags.HasFlag(SeekFlags.ForcePlayer))
			{
				if (_curPlayer != null && _curPlayer.Progress < 1 && _curPlayer.Progress > 0)
					return _curPlayer;
			}
			
			return GetPlayer(tendTo) as Player;
		}
		
		[Flags]
		public enum SeekFlags
		{
			/** Prevents reuse of the current player if the AnimationVariant doesn't match. May cause cross-fade. */
			ForcePlayer = 1<<0,
			/** Prevents the sending of an updated progress as a result of a seek */
			BypassUpdate = 1<<1,
		}
		public void SeekProgress( double newProgress, AnimationVariant tendTo = AnimationVariant.Forward,
			SeekFlags flags = 0 )
		{
			bool bypassUpdate = flags.HasFlag(SeekFlags.BypassUpdate);
			var player =  GetCurrentPlayer(tendTo, flags);
			if (bypassUpdate)
				_prevProgress = newProgress;
			player.SeekProgress(newProgress, !bypassUpdate);
		 }
		
		public void PlayToProgress( double progress, AnimationVariant tendTo = AnimationVariant.Forward,
			SeekFlags flags = 0)
		{
			var player = GetCurrentPlayer(tendTo, flags);
			player.PlayToProgress(progress);
		}
		
	}
}
