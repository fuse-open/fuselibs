using Uno;
using Uno.UX;

namespace Fuse.Animations
{
	internal enum AnimatorVariant
	{
		Allow,
		Disallow,
		HasBackward,
	}
	
	/** 
		Animators are used to specify which and how @Elements are to be animated when a @Trigger is triggered.
		There are three pairs of properties which are important for controlling the exact result of an animation.

		@topic Animators

		## Example

		Examples of animator types are @Change and @Move, as used in this example:

			<Panel ux:Name="panel1" Color="Blue">
				<WhilePressed>
					<Change panel1.Color="#0f0" Duration="1" />
					<Move X="100" Delay="1" Duration="1" />
				</WhilePressed>
			</Panel>

		When the @WhilePressed trigger above is activated when a pointer is pressed on the panel, 
		the animators are played according to their `Delays` and other properties.

		## Duration/DurationBack

		Animators are used to animate elements and properties in response to triggers being activated. There are many animators to choose from, all with different purposes. Common animators include @Move, @Rotate, @Scale and @Change. While these animators animate forward on activation and backward on deactivation, some animators, such as @Spin and @Cycle create a continuous looping animation while active.

		## Delay/DelayBack

		Setting the `Delay` property results in the actual animation being delayed by that amount of seconds. `DelayBack` is used to set a different delay on the backward animation. The total duration of the animation becomes the delay + the duration. The following @Change animator has a total duration of 7 seconds. It waits 5 seconds after being activated and then animates its target element over 2 seconds.

		```
		<Change Delay="5" Duration="2" someElement.Height="100"/>
		```

		## Easing/EasingBack

		Fuse comes with a standard set of predefined easing curves. Easing curves are used to control how an animation progresses over time. The default easing is set to `Linear`. With linear easing, the animation progresses at the same speed over its entire duration. This usually appears quite unnatural and fake. To gain a more natural feel, we can change the easing to `QuadraticInOut`, like so:

		```
		<Change Easing="QuadraticInOut" Duration="2" someElement.Property="SomeValue"/>
		```

		This animator will progress slowly in the beginning, faster in the middle, and then slow again in the end.

		## Track animators

		@TrackAnimator classes have a @Duration as well as a defined target
		value. Animation can be tweaked further using @Easing curves, or custom @Keyframes

		[subclass Fuse.Animations.TrackAnimator]

		## Open / looping animators

		@OpenAnimators classes have infinite duration, and typically loop or repeate forever while
		active.
		[subclass Fuse.Animations.OpenAnimator]
	*/
	public abstract class Animator: PropertyObject
	{
		public IMixer Mixer = Fuse.Animations.Mixer.Default;
		
		/** Seconds from the start of the trigger until this animator should play.

			Note that some triggers are often played backwards in some scenarios. Delay will then be measured
			from the end of the animation, to when this animator should be completed.
		*/
		public double Delay { get; set; }

		internal virtual AnimatorVariant AnimatorVariant { get { return AnimatorVariant.Allow; } }
		
		internal abstract AnimatorState CreateState(CreateStateParams p);
		
		MixOp _mixOp = MixOp.Offset;
		/** How to mix this animator when there are multiple conflicting animators affecting the target. 
			@default MixOp.Offset
		*/
		public MixOp MixOp 
		{ 
			get { return _mixOp; }
			set { _mixOp = value; }
		}
		
		internal virtual double GetDurationWithDelay(AnimationVariant dir)
		{
			return Delay;
		}
		
		internal Animator() { }
	}
	
	class CreateStateParams
	{
		public AnimationVariant Variant;
		public double TotalDuration;
		public Visual Attached;
	}
	
	enum SeekDirection
	{
		Forward,
		Backward,
	}
	
	[Flags]
	enum SeekResult
	{
		None = 0,
		Complete = 1 << 0,
		Stable = 1 << 1,
	}
	
	abstract class AnimatorState
	{
		public AnimationVariant Variant;
		protected Visual Visual;
		protected double TotalDuration;
		
		protected AnimatorState( CreateStateParams p, Visual useVisual = null )
		{
			this.Variant = p.Variant;
			this.Visual = useVisual ?? p.Attached;
			this.TotalDuration = p.TotalDuration;
		}

		//meant only for zero-length animations
		internal abstract SeekResult SeekProgress(double progress, double interval, SeekDirection dir, 
				double strength);
		internal abstract SeekResult SeekTime(double nominal, double interval, SeekDirection dir,
			double strength );

		public virtual bool IsOpenEnd { get { return false; } }
		public virtual void Disable() { }
	}
}
