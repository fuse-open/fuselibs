StateGroup manages a set of @State triggers, making sure only a single @State is active at once.
A @State is a regular @Trigger that is controlled by a @StateGroup.
Animators inside a @State define what should change while that state is active.

The basic structure of a StateGroup looks like this:

```xml
<StateGroup>
	<State ux:Name="firstState" />
	<State ux:Name="secondState" />
</StateGroup>
```

Now, this setup does nothing at all. We need to add some animators to our @States, so that they actually do something.
We'll add a @Panel as well, so we have something to animate.

```xml
<Panel ux:Name="thePanel" Width="100" Height="100" />
	<StateGroup>
		<State ux:Name="firstState">
			<Change thePanel.Color="#f00" />
		</State>
		<State ux:Name="secondState">
			<Change thePanel.Color="#00f" />
		</State>	
	</StateGroup>
</Panel>
```

Since the first @State in a StateGroup will be activated by default, the above example will display a red @Panel.

At this point, we'd like to switch to a different state somehow. This can be achieved in several ways, as seen below.

## The `Active` property

The `Active` property can be used to activate a particular @State.
The below example displays a colored @Panel, along with three buttons that change its color.

```xml
<StackPanel>
	<Panel ux:Name="thePanel" Width="100" Height="100" />

	<StateGroup ux:Name="stateGroup">
		<State ux:Name="redState">
			<Change thePanel.Color="#f00" Duration="0.2"/>
		</State>
		<State ux:Name="greenState">
			<Change thePanel.Color="#0f0" Duration="0.2"/>
		</State>
		<State ux:Name="blueState">
			<Change thePanel.Color="#00f" Duration="0.2"/>
		</State>
	</StateGroup>

	<Grid ColumnCount="3">
		<Button Text="Red">
			<Clicked>
				<Set stateGroup.Active="redState"/>
			</Clicked>
		</Button>
		<Button Text="Green">
			<Clicked>
				<Set stateGroup.Active="greenState"/>
			</Clicked>
		</Button>
		<Button Text="Blue">
			<Clicked>
				<Set stateGroup.Active="blueState"/>
			</Clicked>
		</Button>
	</Grid>
</StackPanel>
```

## TransitionState

Instead of directly jumping to a particular state, the @TransitionState action can be used to advance to the next @State in a StateGroup, following the order in which they are declared.
If a @TransitionState is triggered while the last @State is active, it wraps around to activate the first @State.

The following example displays a panel that will cycle its color between red, green and blue when clicked.

```xml
<Panel ux:Name="thePanel" Width="100" Height="100">
	<StateGroup ux:Name="stateGroup">
		<State ux:Name="redState">
			<Change thePanel.Color="#f00" Duration="0.2"/>
		</State>
		<State ux:Name="greenState">
			<Change thePanel.Color="#0f0" Duration="0.2"/>
		</State>
		<State ux:Name="blueState">
			<Change thePanel.Color="#00f" Duration="0.2"/>
		</State>
	</StateGroup>

	<Clicked>
		<TransitionState Type="Next" Target="stateGroup" />
	</Clicked>
</Panel>
```

## Controlling StateGroup using JavaScript

A `StateGroup` may be controlled via its JavaScript interface.
This is done either by calling the `goto(state)` or `gotoNext()` methods on the @StateGroup itself, or by calling the `goto()` method on a particular @State.

```xml
<JavaScript>
	exports.gotoNextState = function()
	{
		stateGroup.gotoNext();
	}

	exports.gotoSecondState = function()
	{
		stateGroup.goto(secondState);
	}

	exports.gotoThirdState = function()
	{
		thirdState.goto();
	}
</JavaScript>

<StateGroup ux:Name="stateGroup">
	<State ux:Name="firstState">
		<!-- ... -->	
	</State>
	<State ux:Name="secondState">
		<!-- ... -->
	</State>
	<State ux:Name="thirdState">
		<!-- ... -->
	</State>
</StateGroup>

<StackPanel>
	<Button Clicked="{gotoNextState}" Text="Next state" />
	<Button Clicked="{gotoSecondState}" Text="Second state" />
	<Button Clicked="{gotoThirdState}" Text="Third state" />
</StackPanel>
```

## Transition

We can also specify the `Transition` property, which can be either `Exclusive` or `Parallel`.
`Exclusive` means that each state will have to be fully deactivated before the next state becomes active.
`Parallel` means that as one state deactivates, the next one will become active and whatever properties they animate will be interpolated between them.