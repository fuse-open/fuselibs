using Uno;
using Uno.UX;

using Fuse.Animations;

namespace Fuse.Triggers
{
	/*
		em: Deprecated I think. Pulsing only makes sense for `Timeline`.
	*/
	public interface IPulseTrigger
	{
		void Pulse();
	}

	/** Groups several animations together

		This allows for a nice way of grouping several animations together and separating them from the interaction logic.

		A `Timeline` can be played by animating its `TargetProgress` property between 0 and 1.

		> **Note:** `Timeline` itself is *not* intended for grouping multiple animators to create keyframe animations.
		> To achieve this, you can add @Keyframes to the animators themselves.
		>
		> *Incorrect:*
		>
		> ```
		> <Timeline>
		>     <Change rect.Opacity="1" Delay="0.0" Duration="0.5" />
		>     <Change rect.Opacity="0" Delay="0.5" Duration="0.5" />
		> </Timeline>
		> ```
		>
		> *Correct:*
		>
		> ```
		> <Timeline>
		>     <Change Target="rect.Opacity">
		>         <Keyframe Value="1" Time="0.5" />
		>         <Keyframe Value="0" Time="1.0" />
		>     </Change>
		> </Timeline>
		> ```

		## Example

		Here is an example of how we can use a timeline to animate several properties on a rectangle (its width and color), and then play between the start and end of this `Timeline` by clicking two buttons.

			<StackPanel>
				<Rectangle ux:Name="rect" Height="40" Width="100%">
					<SolidColor ux:Name="color" Color="#f00" />
				</Rectangle>
				<Grid ColumnCount="2">
					<Button Text="Red">
						<Clicked>
							<Set timeline.TargetProgress="0" />
						</Clicked>
					</Button>
					<Button Text="Green">
						<Clicked>
							<Set timeline.TargetProgress="1" />
						</Clicked>
					</Button>
				</Grid>

				<Timeline ux:Name="timeline">
					<Change Target="rect.Width">
						<Keyframe Value="10" Time="0.3"/>
						<Keyframe Value="100" Time="0.6"/>
					</Change>
					<Change color.Color="#0f0" Duration="0.3" Delay="0.3"/>
				</Timeline>
			</StackPanel>

	*/
	public partial class Timeline : Trigger, IPlayback, IPulseTrigger
	{
		public Timeline()
		{
			_suppressPropertyChangedProgress = true;
		}
		
		/** Makes triggers active when progress is 0 if `true` */
		public bool OnAtZero
		{
			get { return _startAtZero; }
			set { _startAtZero = value; }
		}
		
		//reflects high level requests to stop/start, not actual animation/trigger playback
		enum State
		{
			Play,
			Stop,
		}
		State _state = State.Play;

		bool _hasInitialProgress;
		double _initialProgress = 0;
		/** Progress which the Timeline should start playing from */
		public double InitialProgress
		{
			get { return _initialProgress; }
			set
			{
				_hasInitialProgress = true;
				_initialProgress = value;
			}
		}
		
		bool _hasTargetProgress;
		double _targetProgress = 0;
		/** Progress at which the Timeline ends */
		public double TargetProgress
		{
			get { return _targetProgress; 	}
			set
			{
				_targetProgress = value;
				_hasTargetProgress = true;
				if (IsRootingCompleted && _state == State.Play)
					PlayTo(_targetProgress);
			}
		}
		
		/** 
			Sets the behavior of the Timeline once the end has been reached.

			Possible values are:

			 * `Once` - timeline stops once the end is reached
			 * `Wrap` - timeline continues playing from the beginning when the end is reached

		  */
		public PlayMode PlayMode
		{
			get { return Animation.PlayMode; }
			set  
			{ 
				Animation.PlayMode = value; 
				//in Wrap mode ensure we're playing forward by default
				if (Animation.PlayMode == PlayMode.Wrap)
				{
					if (!_hasTargetProgress)
						TargetProgress = 1;
					if (!_hasInitialProgress)
						InitialProgress = 0;
				}
			}
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			//when preserved allow base Trigger to manage start
			if (!IsPreservedRootFrame)
			{
				BypassSeek(_initialProgress);
				//em: I couldn't see any use-case where you'd have InitialProgress and want bypass
				if (Bypass == TriggerBypassMode.Standard && !_hasInitialProgress)
					BypassSeek(TargetProgress);
					
				if (_state == State.Play)
					Play(TargetProgress);
			}
		}
		
		static Selector _progressName = "Progress";
		public event ValueChangedHandler<double> ProgressChanged;

		/**
			Stops the playback at the current progress. Sets the TargetProgress to this new progress.
			
			This is not the same as the `IPlayback.Stop` function, nor `Stop` UX action.
		*/
		public void Stop()
		{
			if (IsRootingCompleted)
			{
				Seek(Progress);
				_targetProgress = Progress;
				_state = State.Stop;
			}
		}

		/**
			Plays to a target progress.
			
			You might need to call `TimelinePlayTo` from Uno if calling this directly.
		*/
		public void PlayTo(double progress)
		{
			TimelinePlayTo(progress);
		}
		
		//workaround for Uno visibility defect
		public void TimelinePlayTo(double progress)
		{
			if (IsRootingCompleted)
				Play(progress);
		}
		
		AnimationVariant _lastPlay = AnimationVariant.Forward;
		void Play(double progress)
		{
			_state = State.Play;
			_lastPlay = progress >= Progress ? AnimationVariant.Forward : AnimationVariant.Backward;
			base.PlayTo(progress,_lastPlay);
			_targetProgress = progress;
		}

		/**
			Stops the playback at the current progress. Unlike `Stop` this does not adjust the TargetProgress, a `Resume` can continue playing to the previous target.
		*/
		public void Pause()
		{
			if (IsRootingCompleted)
			{
				_state = State.Stop;
				Seek(Progress);
			}
		}

		/**
			Resumes playing to the TargetProgress.
		*/
		public void Resume()
		{
			if (IsRootingCompleted)
			{
				_state = State.Play;
				base.PlayTo(_targetProgress);
			}
		}

		void IPlayback.Stop() 
		{
			if (IsRootingCompleted)
			{
				Seek(0);
				_targetProgress = 0;
				_state = State.Stop;
			}
		}
		
		void IPlayback.Pause()
		{
			Pause();
		}
		
		void IPlayback.Resume()
		{
			if (IsRootingCompleted)
				Play(_lastPlay == AnimationVariant.Forward ? 1 : 0);
		}
		

		/** Deprecated */
		[Obsolete]
		void IPlayback.PlayTo(double progress)
		{
			PlayTo(progress);
		}
		[Obsolete]
		public bool IPlayback.CanPlayTo { get { return true; } }
		[Obsolete]
		public bool IPlayback.CanStop { get { return true; } }
		[Obsolete]
		public bool IPlayback.CanPause { get { return true; } }
		[Obsolete]
		public bool IPlayback.CanResume { get { return true; } }
		/** End-Deprecated */
		
		
		[UXOriginSetter("SetProgress")]
		/** Current progress of the timeline */
		public new double Progress
		{
			get { return base.Progress; }
			set
			{
				base.Seek(value);
				_targetProgress = value;
			}
		}

		//the origin isn't tracked through the animation update but it needs to be for origin setters
		//to work correctly on Progress. This overrides the sender during setting.
		//mortoray: I'm not very happy with the solution though, since there is no guarantee the
		//progress update must be synchronous.
		IPropertyListener _progressOrigin;
		public void SetProgress(double value, IPropertyListener origin)
		{
			if (origin != this)
			{
				_progressOrigin = origin;
				if (IsRootingCompleted)
					base.Seek(value);
				else if (!_hasInitialProgress)
					_initialProgress = value;
				_progressOrigin = null;
			}
		}

		protected override void OnProgressChanged()
		{
			var sender = _progressOrigin ?? this as IPropertyListener;
			OnPropertyChanged(_progressName, sender);
			if (ProgressChanged != null)
				ProgressChanged(sender, new ValueChangedArgs<double>(Progress));
		}
		
		
		public new void Pulse()
		{
			base.Pulse();
		}
		
		public void PulseForward()
		{
			_targetProgress = 1;
			DirectActivate(BypassOff);
		}
		
		void BypassOff()
		{
			_targetProgress = 0;
			BypassDeactivate();
		}
		
		new public void PulseBackward()
		{
			BypassActivate();
			_targetProgress = 0;
			DirectDeactivate();
		}
	}
}
