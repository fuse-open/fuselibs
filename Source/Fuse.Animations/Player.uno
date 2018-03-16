using Uno;
using Uno.Diagnostics;

namespace Fuse.Animations
{
	/**
		Implements common behavour between animated progress and strength.
		
		IsProgress allows zero-length durations to still have a progress.
		
		Animators where `IsOpenEnd == false` are clamped to a nomimal progress range of 0..1, or
		in duration of 0...Duration.
	*/
	class PlayerPart
	{
		//true if tracking Current in progress mode, false if in time mode
		public bool IsProgress;
		public double Duration;
		public bool Animate;
		//tracks time within the nominal range
		public double Current, Source, Target;
		public double SourceTime;

		const float _zeroTolerance = 1e-05f;

		public PlayerPart( double currentProgress = 0 )
		{
			IsProgress = true;
			Current = currentProgress;
		}
		
		public void PlayToProgress( double progress )
		{
			bool nIsProgress;
			double nTarget;
			
			if (Duration < _zeroTolerance)
			{
				nIsProgress = true;
				nTarget = progress;
			}
			else
			{
				nIsProgress = false;
				nTarget = progress * Duration;
			}

			//avoid timing interruption if same progress (relates to note in MarkSource)
			if (nIsProgress == IsProgress && nTarget == Target && Animate)
				return;
				
			MarkSource(Animate);
			Animate = true;
			IsProgress = nIsProgress;
			Target = nTarget;
		}
		
		void MarkSource(bool isAnimating)
		{
			Source = Current;
			//If currently animating then the current frame must still be considerd for animation
			//this is important for issues like  https://github.com/fusetools/fuselibs-private/issues/788
			//the time check is to avoid double stepping if animation already done this frame
			if (isAnimating && _stepTime < Time.FrameTime)
				SourceTime = Time.FrameTime - (Time.FrameInterval * _timeMultiplier);
			else
				SourceTime = Time.FrameTime;
		}
		
		public void PlayToEnd()
		{
			PlayToProgress(1);
		}
		
		public void PlayToStart()
		{
			PlayToProgress(0);
		}

		double _stepTime;
		public bool Step()
		{
			_stepTime = Time.FrameTime;
			var elapsed = (Time.FrameTime - SourceTime) * _timeMultiplier;

			if (Target > Source)
			{
				Current = IsProgress ? 1.0 : Math.Min( elapsed + Source, Duration );
			}
			else
			{
				Current = IsProgress ? 0.0 : Math.Max( Source - elapsed, 0 );
			}
				
			if ( (Target >= Source && Current >= Target) ||
				(Target <= Source && Current <= Target) )
			{
				Current = Target;
				Animate = false;
			}
			
			return false;
		}
		
		public bool WrapStep()
		{
			//if target is not a wrapping location then treat as normal step
			if (IsProgress || (Target > 0 && Target < Duration))
			{
				return Step();
			}
			
			_stepTime = Time.FrameTime;
			var elapsed = (Time.FrameTime - SourceTime) * _timeMultiplier;
			
			//don't confuse things if there is no elapsed time (this could otherwise wrap a 1 value to 0)
			if (elapsed == 0)
				return false;
				
			Current = (Target > Source) ? (elapsed + Source) : (Source - elapsed);
			
			bool wrap = false;
			if (Current >= Duration || Current < 0)
			{
				var loops = Math.Abs( Math.Floor( Current / Duration ) );
				Current = Math.Mod( Current, Duration );
				SourceTime += Duration * loops / _timeMultiplier;
				wrap = true;
			}

			return wrap;
		}
		
		public void SeekProgress( double p )
		{
			p = Math.Clamp( p, 0, 1 );
			Animate = false;
			if (Duration < _zeroTolerance)
			{
				IsProgress = true;
				Current = p;
			}
			else
			{
				IsProgress = false;
				Current = p * Duration;
			}
		}
		
		public double Progress
		{
			get
			{
				if (IsProgress)
					return Current;
				else
					return Math.Clamp( Current / Duration, 0, 1 );
			}
		}
		
		double _timeMultiplier = 1;
		public void AlterDuration(double t, double timeMult)
		{
			_timeMultiplier = timeMult;
			MarkSource(Animate);
			var p = Progress;
			Duration = t;
			SeekProgress(p);
		}

		public double TimeMultiplier { get { return _timeMultiplier; } }
	}
	
	class Player : IUpdateListener
	{
		public IPlayerFeedback Feedback;
		
		public Visual Visual { get; private set; }
		public TriggerAnimation Animation { get; private set; }
		public AnimationVariant Variant { get; set; }
		public PlayMode Mode { get; private set; }
		
		AnimatorState[] _states;
		AnimatorState[] States
		{
			get
			{
				if (_states == null)
				{
					_states = Animation.CreateAnimatorsState(Variant, Visual);
				}
				return  _states;
			}
		}

		public Player(Visual elm, TriggerAnimation animation, AnimationVariant variant,
			PlayMode mode)
		{
			Animation = animation;
			Visual = elm;
			Variant = variant;
			Mode = mode;
			TimeChanged();
		}
		
		public void TimeChanged()
		{
			_progress.AlterDuration( Animation.GetAnimatorsDuration(Variant), 
				Animation.GetTimeMultiplier(Variant) );
		}

		public double AnimatorsDuration { get { return _progress.Duration; } }
		
		void IUpdateListener.Update() { CheckUpdate(true); }
		
		bool _allStable = true;

		void CheckUpdate(bool interval = false) 
		{ 
			//we step and update state always to ensure sync with current state.
			//Step and UpdateStates both use relative time and are safe to call multple times per frame

			bool running = false;
			
			if (_progress.Animate)
			{	
				var wrapped = Mode == PlayMode.Wrap ? _progress.WrapStep() : _progress.Step();
				if (Feedback != null)
					Feedback.OnProgressUpdated(this, 
						(wrapped ? PlayerFeedbackFlags.Wrapped : PlayerFeedbackFlags.None) |
						PlayerFeedbackFlags.Animated);

				//If the player has a duration then we expect running to be over (done/Stop) after the final
				//frame is displayed for 1-frame. Otherwise in things like `PulseForward` the final frame
				//would essentially be dropped. For triggers without durations however we would expect
				//an immediate turnaround.
				running ||= _progress.IsProgress ? _progress.Animate : true;
			}
			
			if (_strength.Animate)
			{
				_strength.Step();
				
				running ||= _strength.IsProgress ? _strength.Animate : true;
			}

			var stable = UpdateStates(interval);
			if (stable && !running)
				Stop();
			else
				Start();

			//this must come after, since it might involve callbacks that affect the player
			if (!running)
				Done();

			if (stable != _allStable)
			{
				_allStable = stable;
				if (Feedback != null && stable)
					Feedback.OnStable(this);
			}
		}

		public bool IsStable { get { return _allStable; } }
		
		bool _isStarted;
		internal bool TestIsStarted { get { return _isStarted; } }
		
		void Start()
		{
			if (!_isStarted)
			{
				_isStarted = true;
				UpdateManager.AddAction( this );
			}
		}
		
		void Stop()
		{
			if (_isStarted)
			{	
				_isStarted = false;
				UpdateManager.RemoveAction( this );
			}
		}
		
		public void Suspend()
		{
			_progress.Animate = false;
			_strength.Animate = false;
			CheckUpdate();
		}
		
		bool _isDone;
		protected bool IsDone { get { return _isDone; } }
		
		void Done()
		{
			_progress.Animate = false;
			_strength.Animate = false;
			
			if (!_isDone)
			{
				_isDone = true;

				//callback last in case in calls back into Player
				if (Feedback != null) 
					Feedback.OnPlaybackDone(this);
			}
		}
		
		public void Disable()
		{
			Stop();
			
			if (_states != null)
			{
				for (int i = 0; i < _states.Length; i++) 
					_states[i].Disable();
				_states = null;
			}
		}
		
		PlayerPart _progress = new PlayerPart();

		public double Progress { get { return _progress.Progress; } }
		
		public double RemainTime
		{
			get 
			{
				const float zeroTolerance = 1e-05f;
				if (_progress.IsProgress || _progress.Duration < zeroTolerance)
					return 0;
				return Variant == AnimationVariant.Forward ?
					_progress.Duration - _progress.Current :
					_progress.Current;
			}
		}
		
		public void SeekProgress( double progress, bool triggerUpdate = true )
		{
			_progress.SeekProgress( progress );
			_isDone = true; //will not trigger done
			CheckUpdate();
			
			if (triggerUpdate && Feedback != null)
				Feedback.OnProgressUpdated(this, PlayerFeedbackFlags.None);
		}

		internal bool IsSyncState
		{
			get
			{
				return _progress.Current == 0 || _progress.Progress == 1;
			}
		}
		
		bool UpdateStates(bool isInterval)
		{	
			bool allStable = true;

			//in case called multiple times in a frame the interval only applies once (important for
			//OpenAnimator's)
			var interval = isInterval ? (Time.FrameInterval * _progress.TimeMultiplier) : 0.0;
			if (_seekDirection == SeekDirection.Backward)
				interval = -interval;
			
			for (int i=0; i < States.Length;++i)
			{
				var s = States[i];
				SeekResult stable;
				if (_progress.IsProgress)
					stable = s.SeekProgress(_progress.Current, interval, 
						_seekDirection, _strength.Progress );
				else
					stable = s.SeekTime(_progress.Current, interval, _seekDirection,
						_strength.Progress );
					
				allStable = allStable && stable.HasFlag(SeekResult.Stable);
			}

			return allStable;
		}
		
		//it's important to start Backward, if we're trying to be off we must keep going backwards
		//so the OpenAnimator's understand they are off, not just stuck at the beginning.
		SeekDirection _seekDirection = SeekDirection.Backward;
		
		public void PlayToProgress( double progress )
		{	
			if (progress != _progress.Progress)
				_seekDirection = progress > _progress.Progress ? SeekDirection.Forward : SeekDirection.Backward;
			_progress.PlayToProgress(progress);
			_isDone = false;
			CheckUpdate();
		}
		
		public void PlayToEnd()
		{
			_seekDirection = SeekDirection.Forward;
			_progress.PlayToEnd();
			_isDone = false;
			CheckUpdate();
		}
		
		public void PlayToStart()
		{
			_seekDirection = SeekDirection.Backward;
			_progress.PlayToStart();
			_isDone = false;
			CheckUpdate();
		}
		
		PlayerPart _strength = new PlayerPart(1);
		
		public double Strength
		{
			get { return _strength.Progress; }
			set 
			{
				_strength.SeekProgress(value);
				CheckUpdate();
			}
		}
		
		public void FadeIn(double time)
		{
			_strength.AlterDuration(time, 1);
			_strength.PlayToEnd();
			CheckUpdate();
		}
		
		public void FadeOut(double time)
		{
			_strength.AlterDuration(time, 1);
			_strength.PlayToStart();
			CheckUpdate();
		}
	}
	
}
