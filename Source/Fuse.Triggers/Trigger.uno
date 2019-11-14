using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse.Animations;
using Fuse.Triggers.Actions;


namespace Fuse.Triggers
{
	public enum TriggerBypassMode
	{
		/** Changes in state during the root frame are handled as bypass, with special exceptions. */
		Standard,
		/** All changes are treated as normal and nothing is bypassed. */
		Never,
		/** Only changes during the rooting frame are handled as bypass, without special exceptions. */
		Rooting,
		
		/** Deprecated: 2017-07-21
			For possible backwards compatibilty, like Standard but excludes the check for layout bypass.
			This mode should not be used. */
		ExceptLayout,
	}

	public enum TriggerPlayState
	{
		/** Not playing at the moment */
		Stopped,
		/** Playing backwards */
		Backward,
		/** Playing forward */
		Forward,
		/** Something is seeking forward on the trigger */
		SeekBackward,
		/** Something is seeking backward on the trigger */
		SeekForward,
	}
	
	/*
		There are a series of high-level actions, such as `Activate` and their implementations `DirectActivate`
		and `BypassActivate`. In most cases the high-level function should be called (ex. `activate`). It
		will appropriately bypass, or progress normally, base on the rooting and bypass state of the trigger.
		They can also safely be called at any time (even when not rooted), but they will just be ignored in
		that case (on the expectation that OnRooted will call them again correctly).
		
		The `Direct...` and `Bypass...` functions should be called only under special circumstances. They must
		be properly guarded for rooting and bypass state -- thus can lead to exceptions if not called correctly.
	*/

	/**
		Triggers are the main tools for interaction response, transitions and animation in Fuse.
		
		@topic Triggers and animation

		Triggers are objects that can be used in UX markup that detect events, gestures, other user input or
		changes of state in your app, and performs animations and actions in response.

		When a trigger is *activated*, it performs a *timeline of actions* based on what objects you put inside
		the trigger tag.

		Triggers can contain the following types of child-nodes in UX Markup:

		* @Animators that animate properties, transforms or effects when the trigger is active
		* @Actions that perform actions with permanent effects, or call back to JavaScript when the trigger activates.
		* @Nodes (visuals, behaviors, other triggers) that are added to the parent visual while the trigger is active.
		* @Resources (nodes marked with `ux:Key="your_key"`), which overrides `{Resource your_key}` for the parent scope while the trigger is active.

		> See the [remarks section](#section-remarks) at the bottom of this page for more information

		## Available triggers in Fuse
		
		[subclass Fuse.Triggers.Trigger]

		@remarks Docs/TriggersRemarks.md
	*/
	public abstract class Trigger: NodeGroupBase, IUnwrappedPlayerFeedback
	{
		bool _isStarted;
		Action _doneAction;
		bool _doneOn;
		TriggerAnimationState _animState;
		TriggerAnimation _animation;
		List<TriggerAction> _actions;
		TriggerPlayState _lastPlayState = TriggerPlayState.Stopped;
		
		//special mode for Timeline to be in "started" state at Progress==0
		internal bool _startAtZero = false;
		
		TriggerBypassMode _bypass = TriggerBypassMode.Standard;
		/**
			Specifies how changes in state are handled while initializing and rooting the trigger. 

			In some cases, a trigger is rooted to the visual tree while in its active state. In these cases, 
			one could expect one of two things to happen;
			  1. the animation plays from the start as soon as the trigger is rooted.
			  2. the trigger jumps instantly to the end of the animation.

			One can use the `Bypass` property to differentiate between these. The default is `Bypass="Standard"`, 
			which corresponds to case 2. If one wants the effect of case 2, one can use `Bypass="Never"` instead.
		*/
		public TriggerBypassMode Bypass 
		{ 
			get { return _bypass; }
			set
			{
				_bypass = value;
				if (value == TriggerBypassMode.ExceptLayout && !_warnBypass)
				{
					Fuse.Diagnostics.Deprecated( "ExceptLayout mode indicates a problem in trigger expecations and should no tbe used", this );
					_warnBypass = true; //once is enough
				}
			}
		}
		static bool _warnBypass;

		/**
			The animation associated with this trigger.

			This object is created automatically when animators, actions etc. are added to the trigger.

			@advanced
		*/
		public TriggerAnimation Animation
		{
			get
			{
				if (_animation == null) _animation = new TriggerAnimation();
				return _animation;
			}
			set
			{
				_animation = value;
			}
		}

		/**
			Specifies a multiplier to the elapsed time for animation playback.
		*/
		public double TimeMultiplier
		{	
			get { return Animation.TimeMultiplier; }
			set { Animation.TimeMultiplier = value; }
		}
		
		/**
			Stretches the duration of the animation to fill up this period of time.
		*/
		public double StretchDuration
		{
			get { return Animation.StretchDuration; }
			set { Animation.StretchDuration = value; }
		}

		/**
			Specifies an explicit backward animation instead of using the implied backward animation
			of the animators involved. Be aware that actions are not part of the animation.

			Triggers normally use the same animators when deactivating as they do when they activate. There are however 
			animations that require a different set of animators when animating back from the active state. For this purpose
			one can bind a new set of animators to the `BackwardAnimation` property like so:

				<Panel Width="100" Height="100" Color="#00b2ee">
					<WhilePressed>
						<Rotate Degrees="90" Duration="0.5" />
						<Scale Factor="1.5" Duration="1" Easing="QuadraticInOut" />
						<TriggerAnimation ux:Binding="BackwardAnimation">
							<Scale Factor="1.5" Duration="1" Easing="QuadraticInOut" />
						</TriggerAnimation>
					</WhilePressed>
				</Panel>

			In this example, the @Panel only rotates when pressed. When the pointer is released, it does not animate back. 
			Note that the effect of the animators are still reversed. The only difference is that they loose their duration.
		*/
		public TriggerAnimation BackwardAnimation
		{
			get { return Animation.Backward; }
			set { Animation.Backward = value; }
		}
		
		/**
			`true` if there is an explicit backward animation.
		*/
		public bool HasBackwardAnimation
		{
			get { return Animation.HasBackward; }
		}
		
		/**
			If there is a transition between forward/backward playback and two timeilnes are being
			used (implicit or explicit) this specifies the cross-fade time.
		*/
		public double CrossFadeDuration
		{
			get { return Animation.CrossFadeDuration; }
			set { Animation.CrossFadeDuration = value; }
		}

		[UXContent]
		public IList<Animator> Animators { get { return Animation.Animators; } }

		public bool HasAnimators
		{
			get { return _animation != null && _animation.HasAnimators; }
		}

		[UXContent]
		/**
			A list of actions that execute with the trigger. These may react on simple direction
			changes, or at specific time offsets.
		*/
		public IList<TriggerAction> Actions
		{
			get
			{
				if (_actions == null) _actions = new List<TriggerAction>();
				return _actions;
			}
		}

		public bool HasActions
		{
			get { return _actions != null && _actions.Count > 0; }
		}

		void SetDone(Action done, bool on)
		{
			_doneOn = on;
			_doneAction = done;
		}

		/** The current progress of the trigger.

			Triggers are defined over a progress range from 0...1. How a trigger plays over its progress depends on the 
			type of trigger. A trigger at 0 progress is completely deactivated. Content added via the trigger is removed at this time.
			Any progress above 0 will have the content added. Certain animators may delay the removal of content until their animation is completed.
		*/
		public double Progress
		{
			get
			{
				if (_animState != null)
					return _animState.Progress;
				return 0;
			}
		}
		static Selector ProgressName = "Progress";

		//negative backwards, postiive forwards, 0 was stopped. This variable just watches
		//playback and does not influence it
		void SetPlayState(TriggerPlayState next)
		{
			if (next == _lastPlayState)
				return;
			_lastPlayState = next;
			OnPlayStateChanged(next);

			if (next == TriggerPlayState.Stopped || _actions == null)
				return;

			//play direction based triggers
			var dir = IsForward(next) ? TriggerWhen.Forward : TriggerWhen.Backward;
			for (int i=0; i < _actions.Count; ++i)
			{
				var action = _actions[i];
				if (action.IsProgressTriggered)
					continue;

				if (action.When == dir || action.When == TriggerWhen.ForwardAndBackward)
					AddDeferredAction(action);
			}
		}
		
		class DeferredItem
		{
			public TriggerAction Action;
			public Node Node;
			
			public void Perform()
			{
				Action.PerformFromNode(Node);
			}
		}
		void AddDeferredAction(TriggerAction i)
		{
			UpdateManager.AddDeferredAction( new DeferredItem{ Action = i, Node = this }.Perform );
		}
		
		protected virtual void OnPlayStateChanged(TriggerPlayState state)
		{
		}

		//mortoray: I'm undecided on just making this public, nothing should really need it public
		protected internal TriggerPlayState PlayState { get { return _lastPlayState; } }

		void IBasePlayerFeedback.OnPlaybackDone(object s)
		{
			SetPlayState(TriggerPlayState.Stopped);

			if (_animState == null)
			{
				Fuse.Diagnostics.InternalError( "Trigger.OnPlaybackdone called with _animState == null", this );
				return;
			}

			//defer action to end since it may alter our state
			Action perform = null;

			if (_doneAction != null)
			{
				if ( (_doneOn && _animState.ProgressFullOn) ||
					(!_doneOn && _animState.ProgressFullOff) )
				{
					perform = _doneAction;
				}
				_doneAction = null;
			}

			//check in case we had a forced stop (_animState is cleaned, thus no more feedback)
			CleanupStableState();

			if (perform != null)
				perform();
		}

		void IBasePlayerFeedback.OnStable(object s)
		{
			CleanupStableState();
		}

		void CleanupStableState()
		{
			if (_animState == null || !_animState.IsStable)
				return;
			if (_animState.ProgressFullOff && !_startAtZero)
				CleanupState();
		}

		protected void Start()
		{
			if (!_isStarted)
			{
				if (!IsRootingStarted)
				{
					Fuse.Diagnostics.UserError("Warning: Trigger.uno - Trigger started prior to being rooted: ", this );
					return;
				}

				_isStarted = true;
				UseContent = true;
				PlayActions(TriggerWhen.Start);
			}
		}
		
		void PlayActions(TriggerWhen when)
		{
			if (_actions != null)
			{
				for (int i=0; i < _actions.Count; ++i)
				{
					var act = _actions[i];
					//TODO: these are sync, not like PlayState/Progress change actions. This is perhaps not
					//a good idea, but was required for the Navigation preparation stuff (which likely
					//needs to chagne anyway)
					if (act.When == when)
						act.PerformFromNode(this); 
				}
			}
		}

		protected void Stop(bool force = false)
		{
			if (_startAtZero && !force)
				return;

			if (_isStarted)
			{
				PlayActions(TriggerWhen.Stop);
				UseContent = false;
				_isStarted = false;
			}
		}

		bool ShouldIgnore
		{
			get { return !IsRootingStarted; }
		}
		
		/**
			Determines whether an operation should be done in bypass mode. This is used by all the
			high-level functions to determine whether the `Direct...` or `Bypass...` method is called.
		*/
		bool ShouldBypass
		{
			get
			{
				if (Bypass == TriggerBypassMode.Never)
					return false;

				//pretend we were already rooted for preserved frames
				if (IsPreservedRootFrame && Bypass != TriggerBypassMode.Rooting)
					return false;
					
				if (_noLayoutFrame == UpdateManager.FrameIndex && Bypass != TriggerBypassMode.ExceptLayout)
					return true;
					
				if (Node.IsRootCapture(_rootCaptureIndex))
					return true;
				else	
					_rootCaptureIndex = 0;
					
				return !IsRootingCompleted;
			}
		}
		
		int _noLayoutFrame = -1;
		/**
			Indicates the trigger is bound to the layout of a visual. This will keep the trigger in Bypass
			mode until after the first layout of the element is obtained. This is required since layout
			does not happen in the same root grouping/update phase as the creation of the element, yet
			not having a layout should qualify as part of the rooting period.
			
			A trigger that deals with layout should call this during its rooting.
		*/
		protected void RequireLayout(Visual visual)
		{
			if (visual == null || !visual.HasMarginBox)
				_noLayoutFrame = UpdateManager.FrameIndex;
		}
		
		/**
			Activates the trigger (target progress of 1).
			
			This uses the appropriate Direct or Bypass operation.
		*/
		protected void Activate(Action done = null)
		{
			if (ShouldIgnore)
				return;
				
			if (ShouldBypass)
				BypassActivate();
			else
				DirectActivate(done);
		}
		
		protected void BypassActivate()
		{
			BypassSeek(1);
			//must also play to get open ended animations running
			PlayOn();
		}
		
		protected void DirectActivate(Action done = null)
		{
			PlayEnd(true, done);
		}

		/**
			Deactivates the trigger (target progress of 0).
			
			This uses the appropriate Direct or Bypass operation.
		*/
		protected void Deactivate()
		{
			if (ShouldIgnore)
				return;
				
			if (ShouldBypass)
				BypassDeactivate();
			else
				DirectDeactivate();
		}
		
		protected void DirectDeactivate()
		{
			//TODO: Maybe `Stop` should be implied when we reach 0 progress
			PlayEnd(false, StopAction);
		}
		
		protected void BypassDeactivate()
		{
			BypassSeek(0);
			DirectDeactivate();
		}
		
		void StopAction() { Stop(); }

		/**
			Plays the trigger to progress 1 then back to 0. 
			
			This is intended for use in event/pulse-ilke triggers such as `Clicked`.
		*/
		protected void Pulse()
		{
			if (ShouldIgnore)
				return;
				
			//emulate pause to force direction based tirggers to trigger on a pulse
			SetPlayState(TriggerPlayState.Stopped);
			DirectActivate(DirectDeactivate);
		}
		
		/**
			Plays the trigger starting at progress=1 down to 0.
			
			This is a special pulse for inverted animation triggers such as `AddingAnimation`.
		*/
		protected void PulseBackward()
		{
			if (ShouldIgnore)
				return;
				
			BypassActivate();
			DirectDeactivate();
		}
		
		protected void InversePulse()
		{
			PlayEnd(false,PlayOn);
		}

		void PlayOn()
		{
			PlayEnd(true);
		}

		/**
			Play the trigger from where it currently is to the end.
			
			@param on whether to play to progress=1 (true) or to progress=0 (false)
			@param done an action to execute when the progress reaches the desired state (is done)
		*/
		protected void PlayEnd(bool on, Action done = null)
		{
			if (on)
				Start();
			SetDone(done, on);
			
			// direction must be forced in case something activaties/deactivates without an intervening frame.
			// OnProgressUpdate will be called, but with 0 progress. Check progress though to avoid double
			// activation at end while stopped.
			if ( (on && Progress < 1) || (!on && Progress >0 ) || _lastPlayState != TriggerPlayState.Stopped )
				SetPlayState( on ? TriggerPlayState.Forward : TriggerPlayState.Backward );

			//this optimization here is vitally important otherwise you have hundreds of triggers in app
			//repeatedly creating the _animState just to deactivate it.
			if (!on && Progress <= 0 && _animState == null)
			{
				if (done != null)
					done();
				_doneAction = null;
			}
			else if (EnsureState(on ? 1 : 0))
				_animState.PlayEnd(on);
		}

		void CleanupState()
		{
			if (_animState != null)
			{
				_animState.Dispose();
				_animState = null;
			}
		}

		void CreateState()
		{
			CleanupState();
			EnsureAnimationLength();
			_animState = Animation.CreateState(Parent);
			_animState.Feedback = this;
		}

		//return true if there is a state to update
		bool EnsureState(double progress)
		{
			if (progress > 0 || _startAtZero)
			{
				if (_animState == null)// && (HasActions || HasAnimators))
					CreateState();
			}
			return _animState != null;
		}

		void EnsureAnimationLength()
		{
			if (!HasActions)
				return;

			var animFore = Animation.GetAnimatorsDuration(AnimationVariant.Forward);
			var animBack = Animation.GetAnimatorsDuration(AnimationVariant.Backward);

			//find max action timings
			double actFore = 0;
			double actBack = 0;
			for (int i=0; i < _actions.Count; ++i)
			{
				var action = _actions[i];
				var when = action.Delay;
				if (action.When == TriggerWhen.Forward || action.When == TriggerWhen.ForwardAndBackward)
					actFore = Math.Max(when,actFore);
				if (action.When == TriggerWhen.Backward || action.When == TriggerWhen.ForwardAndBackward)
					actBack = Math.Max(when,actBack);
			}

			if (actFore <= animFore && actBack <= animBack)
				return;

			var n = new Nothing();
			n.Delay = actFore;
			n.DelayBack = actBack;
			Animators.Add(n);

			if (HasBackwardAnimation)
			{
				n = new Nothing();
				n.Delay = actBack;
				BackwardAnimation.Animators.Add(n);
			}
		}

		protected void RecreateAnimationState()
		{
			if (_animState != null)
				CreateState();
		}

		protected virtual void OnProgressChanged()
		{
		}

		TriggerPlayState WhatDirection(double diff, bool animating)
		{
			if (animating)
				return diff > 0 ? TriggerPlayState.Forward : diff < 0 ? TriggerPlayState.Backward : TriggerPlayState.Stopped;
			return diff > 0 ? TriggerPlayState.SeekForward : diff < 0 ? TriggerPlayState.SeekBackward : TriggerPlayState.Stopped;
		}
		
		bool IsForward(TriggerPlayState ps) 
		{ 
			return ps == TriggerPlayState.Forward || ps == TriggerPlayState.SeekForward;
		}
		
		bool IsBackward(TriggerPlayState ps)
		{
			return ps == TriggerPlayState.Backward || ps == TriggerPlayState.SeekBackward;
		}

		//allows the Timeline setter to set the origin inside SetProgress/OnProgressChanged. It's kind of a hack, but
		//the alternative would somehow be to track the entire origin throughout the animation layers, just for
		//the one use-case of Timeline. Sender is not needed in the non-Timeline case since Trigger.Progress does
		//not have a setter.
		internal bool _suppressPropertyChangedProgress = false;
		
		void IUnwrappedPlayerFeedback.OnProgressUpdated(object s, double prev, double cur, 
			PlayerFeedbackFlags flags)
		{
			var diff = cur - prev;
				
			SetPlayState(WhatDirection(diff, flags.HasFlag(PlayerFeedbackFlags.Animated)));
			OnProgressChanged();
			if (!_suppressPropertyChangedProgress)
				OnPropertyChanged(ProgressName);

			if (_actions == null)
				return;
				
			var dir = diff > 0 ? TriggerWhen.Forward : TriggerWhen.Backward;
			for (int i=0; i < _actions.Count; ++i)
			{
				var action = _actions[i];
				if (!action.IsProgressTriggered)
					continue;

				var tp = action.ProgressWhen( (float)_animState.CurrentAnimatorsDuration );
				var call = dir == TriggerWhen.Forward ?
					(tp >= prev && tp < cur) || (tp == 1 && cur == 1) :
					(tp <= prev && tp > cur) || (tp == 0 && cur == 0);

				if (call && (action.When == TriggerWhen.ForwardAndBackward || action.When == dir))
					AddDeferredAction(action);
			}
		}

		/**
			Plays to a specific progress with the given animation variant.
			
			Playing follows the duration of time according to the animators in the trigger. Actions
			are executed appropriately.
		*/
		protected void PlayTo(double progress, AnimationVariant variant = AnimationVariant.Forward)
		{
			//force state change even if it never actually animates
			if (progress > Progress)
				SetPlayState( TriggerPlayState.Forward );
			else if (progress < Progress)
				SetPlayState( TriggerPlayState.Backward );
				
			if (EnsureState(progress))
				_animState.PlayToProgress(progress, variant, TriggerAnimationState.SeekFlags.ForcePlayer);
		}

		/**
			Seeks to a specific progress with the given animation variant.
			
			Time is skipped over in seek and the animator's jump directly to the target progress. In non-bypass
			mode the actions will still be triggered (this is important to support user seeking operations
			on gestures). In bypass mode the actions will be skipped.
		*/
		protected void Seek(double progress, AnimationVariant direction = AnimationVariant.Forward)
		{
			if (ShouldIgnore)
				return;
				
			if (ShouldBypass)
				BypassSeek(progress, direction);
			else
				DirectSeek(progress, direction);
		}
		
		protected void DirectSeek(double progress, AnimationVariant direction = AnimationVariant.Forward)
		{
			SeekImpl(progress, direction, TriggerAnimationState.SeekFlags.ForcePlayer);
		}

		protected void BypassSeek(double progress, AnimationVariant direction = AnimationVariant.Forward)
		{
			SeekImpl(progress, direction,
					TriggerAnimationState.SeekFlags.ForcePlayer | TriggerAnimationState.SeekFlags.BypassUpdate );
		}
		
		void SeekImpl(double progress, AnimationVariant direction, TriggerAnimationState.SeekFlags flags)
		{
			if( progress > 0 )
				Start();
			else
				Stop();

			if (EnsureState(progress))
				_animState.SeekProgress(progress, direction,flags);
		}

		int _rootCaptureIndex = 0;
		double _rootProgress;
		TriggerPlayState _rootPlayState;
		protected override void OnRooted()
		{
			base.OnRooted();

			_rootCaptureIndex = Node.RootCaptureIndex;
			if (IsPreservedRootFrame)
			{
				BypassSeek(_rootProgress);
				if (_rootPlayState != TriggerPlayState.Stopped)
					PlayEnd(_rootPlayState == TriggerPlayState.Forward ? true : false, _doneAction );
			}
			else
			{
				_lastPlayState = TriggerPlayState.Stopped;
				_doneAction = null;
				_doneOn = false;

				if (_startAtZero)
				{
					Start();
					EnsureState(0);
				}
			}
		}
		
		internal override void OnPreserveRootFrame()
		{
			base.OnPreserveRootFrame();
			_rootProgress = Progress;
			_rootPlayState = _lastPlayState;
		}
		
		protected override void OnUnrooted()
		{
			Stop(true);
			CleanupState();
			UnrootActions();

			base.OnUnrooted();
		}
		
		void UnrootActions()
		{
			if (_actions == null)
				return;
				
			for (int i=0; i < _actions.Count; ++i)
				_actions[i].Unroot();
		}
		
	}
}
