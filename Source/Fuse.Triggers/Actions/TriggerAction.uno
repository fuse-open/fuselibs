using Uno;
using Uno.UX;

namespace Fuse.Triggers.Actions
{
	public enum TriggerWhen
	{
		Forward,
		Backward,
		ForwardAndBackward,
		Start,
		Stop,
		
		/** DEPRECATED: use ForwardAndBackward */
		Both = ForwardAndBackward,
	}

	/** Trigger actions performs an action at a given delay after a trigger is activated.

		@topic Trigger actions
	
		Actions are similar to @Animators, but are one-off events that fire at a particular point in time. Like animators they are activated by 
		triggers, but their effects are not reversed when their containing trigger is deactivated. Commonly examples of actions include @Set, 
		@Callback, @Hide and @Show.

		## Available trigger actions

		[subclass Fuse.Triggers.Actions.TriggerAction]
	*/
	public abstract class TriggerAction: PropertyObject, ISourceLocation
	{
		TriggerWhen _when = TriggerWhen.Forward;
		public TriggerWhen When
		{
			get { return _when; }
			set { _when = value; }
		}
		
		public TriggerWhen Direction
		{
			get { return When; }
			set 
			{ 
				//DEPRECATED: 2016-11-11
				Fuse.Diagnostics.Deprecated( "Use `Trigger.When` instead of `Trigger.Direction`", this );
				When = value;
			}
		}
		
		/** The node that the action targets. If not specified then the enclsoing Trigger will be used.
			Several triggers can look for a target starting from this point. Some triggers require
			a `Target` to be specified. 
			
			If a trigger has a `Target` then only one of `Target` or `TargetNode` should be used.
		*/
		public Node TargetNode { get; set; }

		float _progress;
		bool _hasProgress;
		float _delay;
		bool _hasDelay;

		/** A value between 0 and 1 for when the action should be performed. Alternative to `Delay`. 

			This proeprty lets us set the fire time relative to the whole duration of the animation. Setting 
			`AtProgress` to 0.5 means that the action is fired half way through	the animation.
		*/
		public float AtProgress 
		{ 
			get { return _progress; }
			set 
			{ 
				_hasProgress = true;
				_progress = value;
			}
		}
		/** The number of seconds after the start of the trigger that the action should be performed. */
		public float Delay
		{
			get { return _delay; }
			set
			{
				_hasDelay = true;
				_delay = value;
			}
		}
		
		public bool IsProgressTriggered
		{
			get { return _hasProgress || _hasDelay; }
		}
		
		bool _isActive = true;
		public bool IsActive 
		{ 
			get { return _isActive;}
			set { _isActive = value; }
		}
		
		public float ProgressWhen( float totalDuration )
		{
			if (_hasProgress)
				return _progress;
			if (_hasDelay)
				return _delay / totalDuration;
			return 0;
		}
		
		public void PerformFromNode(Node target)
		{
			if (IsActive)
				Perform( TargetNode ?? target );
		}
		
		protected abstract void Perform(Node target);
		
		/**
			Called when the owner of this object is unrooted. This gives an action to cleanup resources
			or cancel pending actions.
			
			There is no matching `Rooted` since nothing should be prepared before `Perform`.
			
			Despite this call the action should expect `Peform` to be called again at any time.
		*/
		public void Unroot()
		{
			OnUnrooted();
		}
		
		protected virtual void OnUnrooted() { }
		
		[UXLineNumber]
		/** @hide */
		public int SourceLineNumber { get; set; }
		[UXSourceFileName]
		/** @hide */
		public string SourceFileName { get; set; }
		
		ISourceLocation ISourceLocation.SourceNearest
		{
			get { return this; }
		}
		
	}

}
