namespace Fuse.Triggers
{
	/**
		Helps you create a "pull to reload" interaction with a `ScrollView`.

		It is implemented as a `ScrollingAnimation`, with a set of properties that let you bind different states that should be triggered during different stages of interaction:

		* Pulling - Active when the user is actively pulling down beond the top of the content
		* PulledPastThreshold - Active when the user has pulled down enough to activate loading
		* Loading - Active when the "loading" has started. Loading starts when the user has pulled past the threshold, and then leaves the threshold area.
		* Rest - Active when the user has pulled down the content, but their last movement was upwards.
		In addition, you have a callback, `ReloadHandler`, which is called when the `Loading` state activates.

		* Note that `PullToReload` inherits from @ScrollingAnimation and therefore can be tweaked further using its properties. Here is an example of how we can tweak it to be pulled from the bottom instead using the `Range` property from `ScrollingAnimation`:

		```
		<PullToReload Range="SnapMax">
			...
		</PullToReload>
		```

		See the [Pull to reload](/examples/pull-to-reload), for a complete example on how to use it.

		# Example
		
		The following example flashes the app background in different colors as the different states of the `PullToReload` happen:

			<ScrollView>
				<PullToReload>
					<Timeline ux:Name="redFlash">
						<Change color.Color="#F00" Duration="1"/>
					</Timeline>
					<Timeline ux:Name="pinkFlash">
						<Change color.Color="#FFC0DB" Duration="1"/>
					</Timeline>
					<Timeline ux:Name="greenFlash">
						<Change color.Color="#0F0" Duration="1"/>
					</Timeline>
					<Timeline ux:Name="blueFlash">
						<Change color.Color="#00F" Duration="1"/>
					</Timeline>
					<State ux:Binding="Pulling">
						<Cycle Target="redFlash.Progress" Low="0" High="1" Frequency="1" />
					</State>
					<State ux:Binding="PulledPastThreshold">
						<Cycle Target="pinkFlash.Progress" Low="0" High="1" Frequency="1" />
					</State>
					<State ux:Binding="Loading">
						<Cycle Target="greenFlash.Progress" Low="0" High="1" Frequency="1" />
					</State>
					<State ux:Binding="Rest">
						<Cycle Target="blueFlash.Progress" Low="0" High="1" Frequency="1" />
					</State>
				</PullToReload>
				<StackPanel>
					<Text Margin="20">The quick brown fox</Text>
					<Text Margin="20">Jumps over the lazy dog</Text>
				</StackPanel>
				<SolidColor ux:Name="color" Color="#FFF"/>
			</ScrollView>
	*/
	public partial class PullToReload
	{

	}
}
