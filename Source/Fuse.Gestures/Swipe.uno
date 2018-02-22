using Uno;
using Uno.UX;

using Fuse.Animations;
using Fuse.Elements;
using Fuse.Input;
using Fuse.Scripting;
using Fuse.Triggers;

using Fuse.Gestures.Internal;

namespace Fuse.Gestures
{
	/** The direction that the pointer was swiped. */
	public enum SwipeDirection
	{
		Left,
		Up,
		Right,
		Down,
	}
	
	/** Determines the behavior of a @SwipeGesture. */
	public enum SwipeType
	{
		/** Swipes are completed when the pointer is released
			after the user has swiped over the entire distance of the @SwipeGesture.
		*/
		Simple,
		/** Swiping toggles between an active/inactive state.
			
			The @WhileSwipeActive trigger will be active while its source @SwipeGesture has `Type="Active"`
			and has been swiped to its active state.
			
			We can alter the state of an Active-type @SwipeGesture using
			[SetSwipeActive](api:fuse/gestures/setswipeactive) and/or
			[ToggleSwipeActive](api:fuse/gestures/toggleswipeactive).
		*/
		Active,
		/** Swipes are completed when the user has swiped over the entire distance of the @SwipeGesture,
			and further swipes can be initiated without releasing the pointer.
			
			Swipes in the same direction cannot be activated in sequence: Left-Left is excluded, but Left-Up-Left would be triggered.
		*/
		Auto,
	}
	
	/** Recognizes a swipe (the movement of a pointer in a given direction).
	
		@topic Swipe Gestures
		@include Docs/SwipeGesture/Brief.md
		@remarks Docs/SwipeGesture/Remarks.md
		@examples Docs/SwipeGesture/Examples.md
	*/
	public class SwipeGesture : Behavior, IPropertyListener
	{
		public SwipeGesture()
		{
			Type = SwipeType.Simple;
			Direction = SwipeDirection.Left;
		}
		
		Swiper _swiper;
		SwipeRegion _region = new SwipeRegion();

		internal Swiper TestSwiper { get { return _swiper; } }
		
		SwipeType _type;
		/**
			The type of swipe to detect. See @SwipeType.
		*/
		public SwipeType Type
		{
			get { return _type; }
			set 
			{ 
				_type = value; 
				_region.IsInterruptible = Type != SwipeType.Simple;
				_region.RevertActive = Type != SwipeType.Active;
				_region.AutoTrigger = Type == SwipeType.Auto;
				
				//Active type has automatic completed when the halfway mark is reached (unless overridden)
				if (_type == SwipeType.Active && !_hasThreshold)
				{
					_region.ActivationThreshold = 0.5f;
					_region.DeactivationThreshold = 0.5f;
				}
			}
		}
		
		bool _hasEdge;
		Edge _edge;
		/**
			If specified, this makes the swipe gesture activate from the edge of the parent element.
			
			See [edge swipes](#edge-swipes).

			> **Note:** Only one of `Edge` or `Direction` can be specified.
		*/

		public Edge Edge
		{
			get { return _edge; }
			set
			{
				_edge = value;
				_hasEdge = true;
				//priority of edges is to ensure a deterministic ordering
				_region.Area = SwipeRegionArea.Vector;
				switch (_edge)
				{
					case Edge.Left:
						_region.AreaVector = float4(0,0,0,1);
						_region.Direction = float2(1,0);
						_region.Priority = 1;
						break;
					case Edge.Top:
						_region.AreaVector = float4(0,0,1,0);
						_region.Direction = float2(0,1);
						_region.Priority = 2;
						break;
					case Edge.Right:
						_region.AreaVector = float4(1,0,1,1);
						_region.Direction = float2(-1,0);
						_region.Priority = 3;
						break;
					case Edge.Bottom:
						_region.AreaVector = float4(0,1,1,1);
						_region.Direction = float2(0,-1);
						_region.Priority = 4;
						break;
				}
			}
		}
		
		bool _hasDirection;
		SwipeDirection _direction;
	    
		/**
			The direction of movement to detect swipe gestures for.

			When `Type="Active"`, the opposite direction is used to deactivate the trigger.
		*/
    
		public SwipeDirection Direction
		{
			get { return _direction; }
			set
			{
				_direction = value;
				_hasDirection = true;
				_region.Area = SwipeRegionArea.All;
				
				switch(Direction)
				{
					case SwipeDirection.Left:
						_region.Direction = float2(-1,0);
						_region.Priority = 101;
						break;
					case SwipeDirection.Up:
						_region.Direction = float2(0,-1);
						_region.Priority = 102;
						break;
					case SwipeDirection.Right:
						_region.Direction = float2(1,0);
						_region.Priority = 103;
						break;
					case SwipeDirection.Down:
						_region.Direction = float2(0,1);
						_region.Priority = 104;
						break;
				}
			}
		}
		
		/**
			The total distance that must be covered in order for the swipe to complete.

			This is used to determine the progress of the swipe gesture.
			
			Note that since SwipeGesture applies some physics, deceleration also counts when calculating
			progress.
		*/
    
		public float Length
		{
			get { return (float)_region.Length; }
			set { _region.Length = value; }
		}
		
		/**
			If specified, the SwipeGesture will measure the given element to determine its `Length`.
			
			See [length based on element size](api:fuse/gestures/swipegesture#length-based-on-element-size).
		*/
		public Element LengthNode
		{
			get { return _region.LengthElement; }
			set { _region.LengthElement = value; }
		}
		
		/**
			For [edge](api:fuse/gestures/swipegesture#edge) SwipeGestures, `HitSize` determines the maximum distance
			from the edge (in points) that swipes can begin at.
		*/

		public float HitSize
		{
			get { return _region.AreaVectorDistance; }
			set { _region.AreaVectorDistance = value; }
		}

		public bool IsEnabled
		{
			get { return _region.IsEnabled; }
			set { _region.IsEnabled = value; }
		}
		
		internal static Selector GesturePriorityName = "GesturePriority";
		GesturePriority _gesturePriority = GesturePriority.Low;
		/**
			The priority of the swiping gesture when competing with other gestures.
			
			The default is Lower. 
			
			Mutliple `SwipeGesture` behaviours in the same node become part of a single compound gesture. The priority is applied, but once the gesture acquires a hard capture (becomes solely recognized), a lower priority swipe may then nonetheless be triggered (should the pointer direction change).
			
			@advanced
			@experimental
		*/
		public GesturePriority GesturePriority
		{
			get { return _region.GesturePriority; }
			set { _region.GesturePriority = value; }
		}
		
		bool _hasThreshold;
		/**
			The relative distance that must be travelled before the gesture automatically completes.
			
			The default when Type != Active is `1`, meaning the user must travel, or swipe with enough velocity, to cover the full distance. When `Type == Active` the default is `0.5`, meaning the panel will automatically open/close when the half-way point is reached.
			
			A separate value for activation and deactivating can be specified. The first value of the `float2` is the activation threshold, and the second value the deactivation threshold.
		*/
		public float2 Threshold 
		{
			get { return float2(_region.ActivationThreshold, 1-_region.DeactivationThreshold); }
			set
			{
				_hasThreshold = true;
				_region.ActivationThreshold = value[0];
				_region.DeactivationThreshold = 1-value[1];
			}
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();
			var element = Parent as Element;
			if (element == null)
			{
				Fuse.Diagnostics.UserRootError( "Element", Parent, this );
				return;
			}
				
			_region.SetActive(IsActive);
			_swiper = Swiper.AttachSwiper(element);
			_swiper.AddRegion(Region);
			_region.AddPropertyListener(this);
		}

		void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector prop)
		{
			if (obj == _region && prop == _isActiveName)
				OnPropertyChanged(_isActiveName, _region);
		}

		/* Should only be used to subscribe to events. When the remaining properties are set is undefined */
		internal SwipeRegion Region
		{
			get { return _region; }
		}
		
		protected override void OnUnrooted()
		{
			_region.RemovePropertyListener(this);
			
			if (_swiper != null)
			{
				_swiper.RemoveRegion(_region);
				_swiper.Detach();
				_swiper = null;
			}
			base.OnUnrooted();
		}
		
		[UXOriginSetter("SetIsActive")]
		/** `true` if the SwipeGesture has `Type="Active"` and has been swiped to the active state. */
		public bool IsActive
		{
			get { return _region.IsActive; }
			set { SetIsActive(value, this); }
		}
		
		public void SetIsActive(bool value, IPropertyListener origin)
		{
			SetActive(value, origin);
		}
		
		internal void SetActive(bool value, IPropertyListener origin, bool bypass = false)
		{
			if (_swiper == null)
				_region.SetIsActive(value, origin);
			else
				_swiper.SetActivation(_region, value, bypass);
		}
		
		static Selector _isActiveName = "IsActive";
	}

	/**
	A trigger that maps the progress of a SwipeGesture to a series of animations.

	When the pointer is first pressed down on the @Element, progess will be `0`,
	and will move towards `1` as the pointer is dragged towards the `Length` of the @SwipeGesture.

	# Examples

	In this example, a panel moves 200 points to the right when swiped over a distance of 200 points.

		<Panel Width="100" Height="100" Background="#000">
			<SwipeGesture ux:Name="swipe" Direction="Right" Length="200" />
			<SwipingAnimation Source="swipe">
				<Move X="200" />
			</SwipingAnimation>
		</Panel>

	In this example, we demonstrate using the `LengthNode` property of @(SwipeGesture),
	and the `RelativeNode` property of @(Move), to determine the swipe length based on the width of the panel.

		<Panel ux:Name="parentContainer" Margin="40">
			<Panel Width="60" Height="60" Background="#000" Alignment="Left">
				<SwipeGesture ux:Name="swipe" Direction="Right" Type="Active" LengthNode="parentContainer" />
				<SwipingAnimation Source="swipe">
					<Move X="1" RelativeTo="Size" RelativeNode="parentContainer" />
				</SwipingAnimation>
			</Panel>
		</Panel>
	*/
	public class SwipingAnimation : Trigger, IPropertyListener
	{
		/** Attach to this `SwipeGesture` */
		public SwipeGesture Source { get; private set; }
	
		SwipeRegion _region;
		
		[UXConstructor]
		public SwipingAnimation( [UXParameter("Source")] SwipeGesture source)
		{
			Source = source;
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();
			_region = Source.Region;
			_region.AddPropertyListener(this);
			OnProgressChanged(Source.Region.Progress);
		}
		
		protected override void OnUnrooted()
		{
			_region.RemovePropertyListener(this);
			base.OnUnrooted();
		}

		void IPropertyListener.OnPropertyChanged(PropertyObject sender, Selector prop)
		{
			if (sender != _region || prop != SwipeRegion.ProgressName) return;
			OnProgressChanged(_region.Progress);
		}

		void OnProgressChanged(double progress)
		{
			var diff = progress - Source.Region.StableProgress;
			Seek(progress, diff >= 0 ? AnimationVariant.Forward : AnimationVariant.Backward);
		}
	}

	/**
		Sets the state of an [Active](api:fuse/gestures/swipegesture#swipetype-active-overview)-type @SwipeGesture.

		# Example
		
			<SwipeGesture ux:Name="swipe" Direction="Right" Length="100" Type="Active" />
			
			<Button Text="Close">
				<Clicked>
					<SetSwipeActive Target="swipe" Value="false" />
				</Clicked>
			</Button>
	*/
	public class SetSwipeActive : Fuse.Triggers.Actions.TriggerAction
	{
		/** The @SwipeGesture to set the state of. */
		public SwipeGesture Target { get; set; }
		
		/** `true` if the @SwipeGesture should be transitioned to the active state, `false` for inactive. */
		public bool Value { get; set; }
		
		/** Set to `true` to skip animation. */
		public bool Bypass { get; set; }

		protected override void Perform(Node target)
		{
			if (Target != null)
				Target.SetActive(Value,null, Bypass);
		}
	}

	/**
		Toggles an [Active](api:fuse/gestures/swipegesture#swipetype-active-overview)-type @SwipeGesture on or off.

		# Example
		
		In this example, a `SwipeGesture` is toggled when a button is pressed.

			<SwipeGesture ux:Name="swipe" Direction="Right" Length="100" Type="Active" />
			
			<Button Text="Toggle">
				<Clicked>
					<ToggleSwipeActive Target="swipe" />
				</Clicked>
			</Button>
	*/
	public class ToggleSwipeActive : Fuse.Triggers.Actions.TriggerAction
	{
		/** The @SwipeGesture to toggle. */
		public SwipeGesture Target { get; set; }
		
		protected override void Perform(Node target)
		{
			if (Target != null)
				Target.SetActive(!Target.IsActive,null);
		}
	}

	/** Active whenever an [Active](api:fuse/gestures/swipegesture#swipetype-active-overview)-type
		@SwipeGesture has been swiped to the active state.

		# Example
		
		This example shows a `Panel` that is scaled by a factor of 1.5 while the `SwipeGesture` is active:

			<Panel Width="100" Height="100" Background="#000">
				<SwipeGesture ux:Name="swipe" Direction="Up" Length="50" Type="Simple" />
				<WhileSwipeActive Source="swipe">
					<Scale Factor="1.5" Duration="0.4" />
				</WhileSwipeActive>
			</Panel>
	*/
	public class WhileSwipeActive : WhileTrigger, IPropertyListener
	{
		/** The @SwipeGesture that this trigger should respond to. */
		public SwipeGesture Source { get; private set; }

		SwipeRegion _region;

		float _threshold = 1;
		/**
			The gesture progress at which this trigger is active. The gesture has a progress from 0..1 measured across it's length. 
			
				<Panel Width="100" Height="100" Background="#000">
					<SwipeGesture ux:Name="swipe" Direction="Up" Length="50"/>
					<WhileSwipeActive Source="swipe" Threshold="0.5">
						<Scale Factor="1.5" Duration="0.4" />
					</WhileSwipeActive>
				</Panel>
				
			The `Scale` will apply as soon as the user swipes 25 points, `0.5` of the total `Length`.
		*/
		public float Threshold
		{
			get { return _threshold; }
			set { _threshold = value; }
		}
		
		[UXConstructor]
		public WhileSwipeActive( [UXParameter("Source")] SwipeGesture source)
		{
			Source = source;
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();
			_region = Source.Region;
			_region.AddPropertyListener(this);
			OnProgressChanged(Source.Region.Progress);
		}
		
		protected override void OnUnrooted()
		{
			_region.RemovePropertyListener(this);
			base.OnUnrooted();
		}

		void IPropertyListener.OnPropertyChanged(PropertyObject sender, Selector prop)
		{
			if (sender != _region || prop != SwipeRegion.ProgressName) return;
			OnProgressChanged(_region.Progress);
		}

		void OnProgressChanged(double progress)
		{
			SetActive( progress >= Threshold);
		}
	}

	/** Used by [Swiped](api:fuse/gestures/swiped) to only trigger on certain state transitions. */
	public enum SwipedHow
	{
		/**
			A transition to the *active* state, triggered by
			a swipe in the `Direction` of the @SwipeGesture
		*/
		ToActive,
		/**
			A transition to the *inactive* state, triggered by
			a swipe in the *opposite* `Direction` of the @SwipeGesture.
		*/
		ToInactive,
		/** A transition to either the active or inactive state */
		ToEither,
		/** The user started swiping but didn't swipe far enough to trigger a change */
		Cancelled,
	}

	/**
		Pulse trigger that activates when a swipe has occurred.

		By default, `Swiped` will only trigger when swiping to the primary swipe direction (when it enters the active state).
		For instance, if the @SwipeGesture has `Direction="Left"` it only triggers on a `Left` swipe and ignores the matching closing swipe.
		We can control this behavior by setting the `How` property to either `ToActive` (default), `ToInactive` or `ToEither`.

		> **Note:** For a `Type="Active"` @SwipeGesture, this only fires when the state actually changes.
		> If the user starts swiping but release the pointer without completing the gesture, it will not activate.

		# Example

		This example shows a quick animation after a panel has been swiped.

			<Panel Width="100" Height="100">
				<SwipeGesture ux:Name="swipe" Direction="Up" Length="50" Type="Simple" />
				<Swiped Source="swipe">
					<Scale Factor="1.5" Duration="0.4" DurationBack="0.2" />
				</Swiped>
			</Panel>
	*/
	public class Swiped : Trigger
	{
		/** The @SwipeGesture that this trigger should respond to. */
		public SwipeGesture Source { get; private set; }
		
		[UXConstructor]
		public Swiped( [UXParameter("Source")] SwipeGesture source)
		{
			Source = source;
		}
	
		SwipedHow _how = SwipedHow.ToActive;
		/**
			Specifies the matching criteria for the swipe.
			
			Note that only Active-type @SwipeGestures can produce a `ToInactive` event.
		*/
		public SwipedHow How
		{
			get { return _how;}
			set { _how = value; }
		}
		
		SwipeRegion _region;
		protected override void OnRooted()
		{
			base.OnRooted();
			_region = Source.Region;
			_region.Swiped += OnSwiped;
		}
		
		protected override void OnUnrooted()
		{
			_region.Swiped -= OnSwiped;
			base.OnUnrooted();
		}

		void OnSwiped(bool v, bool cancelled)
		{
			if (cancelled)
			{
				if (How == SwipedHow.Cancelled)
					Pulse();
				return;
			}
				
			if (v && (How == SwipedHow.ToActive || How == SwipedHow.ToEither))
				Pulse();
			if (!v && (How == SwipedHow.ToInactive || How == SwipedHow.ToEither))
				Pulse();
		}
	}

	/**
		Is active while a swiping gesture is in progress. 
		
		A swiping gesture is in progress while the user is swiping, as well as the time it takes the animation to complete the full length of the gesture. Invsersely, this trigger is inactive when the gesture is completely stable.
	*/
	public class WhileSwiping : WhileTrigger, IPropertyListener
	{
		/** The @SwipeGesture that this trigger should respond to. */
		public SwipeGesture Source { get; private set; }

		SwipeRegion _region;

		[UXConstructor]
		public WhileSwiping( [UXParameter("Source")] SwipeGesture source)
		{
			Source = source;
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();
			_region = Source.Region;
			_region.AddPropertyListener(this);
			OnInProgressChanged(_region.InProgress);
		}
		
		protected override void OnUnrooted()
		{
			_region.RemovePropertyListener(this);
			base.OnUnrooted();
		}

		void IPropertyListener.OnPropertyChanged(PropertyObject sender, Selector prop)
		{
			if (sender != _region || prop != SwipeRegion.InProgressName) return;
			OnInProgressChanged(_region.InProgress);
		}

		void OnInProgressChanged(bool inProgress)
		{
			SetActive(inProgress);
		}
	}
	
}
