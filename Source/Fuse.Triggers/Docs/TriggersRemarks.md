## Rest state and deviation

The default layout and configuration of UX markup elements is called the rest state. Triggers define deviations from this rest state.

Each trigger knows how to "un-apply" its own animation to return to the rest state, even if interrupted mid-animation. This is great because 
it means animation is completely separated from the logical state of your program, greatly reducing the complexity of dealing with combined
animation on multiple devices, screen sizes, with real data and real user input.


## Pulse triggers

Pulse triggers detect one-off events such as @Clicked or @Tapped, and play their timeline once. A typical
use case is to do a @Callback to JavaScript:

	<Panel Color="Blue">
		<Tapped>
			<Callback Handler="{panelTapped}" />
		</Tapped>
	</Panel>

Pulse triggers typically have names that are past-tense verbs.

## While-triggers

Triggers with names starting with `While...` are sustained triggers that activate under certain conditions, and remain active until that 
condition goes away. 

For example @WhilePressed activates while the containing visual is pressed by a pointer, and deactivates when the pointer is released.

	<Panel Color="Red" ux:Name="panel">
		<WhilePressed>
			<Scale Factor="0.9" Duration="0.2" Easing="BackOut" />
			<Change panel.Color="Blue" Delay="0.2" Duration="0.2" Easing="CubicOut" />
		</WhilePressed>
	</Panel>

The containing timeline starts plaing from the beginning when a pointer is pressed, and sustains the end state of the animation while the
pointer remains pressed. If the pointer is released in the middle of the animation, the progress is cancelled and recedes naturally from 
its progress at the time of the release.

### Animation-triggers

Triggers with names ending in `...Animation` are specialized for certain controls. They map the logical progress of the control to the progress of the animation.

For example, the progress of a @ScrollingAnimation is tied to the relative scroll position of a @ScrollView. When scrolled to the start of the progress is 0, and when scrolled to the end the progress is 1.

The progress here "seeks" to the target value. For example, a sudden jump in the @ScrollView position will result in a sudden jump in the trigger animations. This ensures the trigger progress is tied precisely to the user input.

The @Animator.Delay and @Animator.Duration settings of animators are respected in `...Animation` triggers, but only as relative values (they are normalized over the range of 0...1 to match the progress).

## Bypass

When a trigger is rooted already in its active state it executes in "bypass" mode. This will not trigger any pulse actions, and it will skip over animations, simply putting them in their final state.

This default can be override by specifying `Byass="Never"` on a trigger.

Various actions and functions also offer the option to use a bypass mode in the transition. These work in the same way by skipping animations and not triggering and pulse actions.
