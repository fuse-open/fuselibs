Unlike the `EnteringAnimation` and `ExitingAnimation` triggers, `Transition` allows you to make different animations depending on which page is being navigating to, or away from.

# Example

	<Page ux:Template="Main">
		<Transition To="Contacts">
			<Move X="-1" RelativeTo="ParentSize" Duration="1"/>
		</Transition>
		<Transition>
			<Move Y="1" RelativeTo="ParentSize" Duration="1"/>
		</Transition>
	</Page>
	
This page has a special transition if navigating to the `Contacts` page. In this case it will slide the page to the left. All other transitions away from this page will slide down.

# To / From

Every navigation change defines a "To" and "From" page. In `Transition` these are always defined as the the forward ordering of the pages in the navigation. This ensures that when navigating backward (such as using `goBack`) the same transitions will be used, but done in reverse.

For example, a `<Transition To="Contacts">` matches a forward transition to the `Contacts` page, as well as a backwards transition from the `Contacts` page to this one.

Similarly, a `<Transtion From="Main">` matches a forward transition from the `Main` page, as well as a backwards transition from this page to the `Main` page.

# Priority

Only one `Transition`, the one with the highest priority, will be selected for each page change. The priority ordering is:

- A `Style` match on the operational style
- `Interaction` match other than `Any`
- `To` page name match
- `From` page name match
- `Direction` of `ToBack`, `FromBack`, `ToFront`, `FromFront`
- `Direction` of `ToActive`, `ToInactive`
- `Direction` of `InFront`, `Behind`
- `Direction` `Any`

If no matching `Transition` is found then a default one will be created according to the [Navigator.Transition](api:fuse/controls/navigationcontrol/transition) property. If you don't want a default then specify a final fallback transition without properties `<Transition>`.

# Play direction

If the page is becoming inactive the transition will be played forward. If the page is becoming active the transition will be played backward. This means the transition is always defining the animation towards the inactive state.

With certain combinations of properties this may at first seem odd, for example:

	<Transition Direction="ToActive">
		<Move X="100" Duration="1"/>
	</Transition>
	
This `Transition` is only selected when the page is becoming the active one. The animation will start at `X=100` and move towards `X=0` over a duration of `1`.

The final state of any active page is always with all transitions deactivated.

