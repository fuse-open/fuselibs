# Basic usage

A SwipeGesture must be attached to an @Element, and will begin detecting swipes when the pointer is pressed
down on that element. Attaching a @SwipeGesture to an @Element is simply adding it as a child:

	<Panel>
		<SwipeGesture ux:Name="swipe" Direction="Right" Length="200" />
	</Panel>

The snippet above will recognize swipe gestures moving from left to right,
over a distance of 200 points.

However, this isn't doing anything useful yet. Let's add a trigger!

	<Panel Width="100" Height="100" Background="Black">
		<SwipeGesture ux:Name="swipe" Direction="Right" Length="200" />
		<SwipingAnimation Source="swipe">
			<Move X="200" />
		</SwipingAnimation>
	</Panel>
	
We've now added a @SwipingAnimation, which will map the progress of our swipe gesture onto a series of
animations. In this case, we are moving the panel over the same distance as the `Length` of our
SwipeGesture, resulting in the panel moving along with the pointer.

> Note that we've referenced our SwipeGesture via the `Source` property of @SwipingAnimation.
> This is because it is possible to have [multiple swipe gestures](#multiple-swipegestures) on a single element,
> so it must be referenced explicitly. All swipe-related triggers share this property.

We also want to respond when the swipe has completed, which is achieved using the
[Swiped](api:fuse/gestures/swiped) trigger. Let's extend our previous example a bit.

	<Panel Width="100" Height="100" Background="Black">
		<SwipeGesture ux:Name="swipe" Direction="Right" Length="200" />
		<SwipingAnimation Source="swipe">
			<Move X="200" />
		</SwipingAnimation>
		
		<Swiped>
			<DebugAction Message="Swiped!" />
		</Swiped>
	</Panel>

For illustrative purposes, we are using @DebugAction to log a message
to the console when the swipe has completed.

# Swipe types

SwipeGesture is designed to handle multiple scenarios,
and can have one of three [types](api:fuse/gestures/swipetype), specified via the `Type` property.

The [type](api:fuse/gestures/swipetype) of a SwipeGesture determines its behavior, and below we'll explain each one.

## [Simple](api:fuse/gestures/swipetype/simple)

`Simple` is the default @SwipeType, and thus the one we have been using so far in this article.

When using this type, swipes are treated as one-off events, and swipes will complete once the pointer is released.

## [Auto](api:fuse/gestures/swipetype/auto)

`Auto` is *almost* identical to `Simple`, however swipes complete once the user has swiped over the entire
distance of the SwipeGesture, without the user needing to release the pointer.
This allows multiple SwipeGestures to be triggered in sequence without releasing the pointer.

<a id="swipetype-active-overview"></a>

## [Active](api:fuse/gestures/swipetype/active)

`Type="Active"` makes swipes toggle between an active/inactive state.
Swiping in the @Direction of the SwipeGesture will transition to the *active* state,
while swiping in the opposite direction will transition to the *inactive* state.

We can alter the state of an Active-type SwipeGesture using
[SetSwipeActive](api:fuse/gestures/setswipeactive) and/or
[ToggleSwipeActive](api:fuse/gestures/toggleswipeactive).

### Reacting to state transitions

When using the `Active` type, we can optionally configure the [Swiped](api:fuse/gestures/swiped) trigger
to respond to only activation or only deactivation.

	<Swiped How="ToActive">
	<Swiped How="ToInactive">

In addition, the @WhileSwipeActive trigger will be active while its source @SwipeGesture is an Active-type
SwipeGesture, and has been swiped to its active state.

# Edge

Instead of specifying a `Direction`, we may provide an `Edge`. This will make the SwipeGesture detect swipes
originating at a given edge of its parent element.

We can also customize the size of the edge area using the `HitSize` property.
It accepts a single number, which represents the maximum distance from the edge (in points) that swipes can
begin at.

# Length based on element size

Instead of specifying a fixed `Length` for the gesture,
we can supply an @Element to be measured via the `LengthNode` property.

This is a powerful feature, as it allows us to create swipe-based controls that work regardless of their size.

Below is an example of a size-independent switch control implemented using SwipeGesture.

	<Panel Height="50">
		<Circle Width="50" Height="50" Color="#000" Alignment="Left">
			<SwipeGesture ux:Name="swipe" LengthNode="track" Direction="Right" Type="Active" />
			<SwipingAnimation Source="swipe">
				<Move X="1" RelativeTo="Size" RelativeNode="track" />
			</SwipingAnimation>
		</Circle>
		
		<Rectangle ux:Name="track" Height="15" Color="#0003" Margin="25,0" CornerRadius="15" />
	</Panel>