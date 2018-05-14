namespace Alive
{
	/**
		Reveals a button when the user swipes left on its contents.
		A confirmation message is shown when the button is tapped.

		```
		<Alive.SwipeActionPanel ButtonText="Do nothing" ConfirmationText="And thus, nothing was done">
			<Panel Color="#fff" Height="80" />
		</Alive.SwipeActionPanel>
		```

		When the button is tapped, this component will raise a UserEvent named Alive.SwipeActionConfirmed.
		You can handle this event using the Alive.SwipeActionConfirmed trigger.

			<JavaScript>
				exports.onConfirmed = function() {
					doSomething();
				}
			</JavaScript>

			<Alive.SwipeActionPanel>
				<Alive.SwipeActionConfirmed Handler="{onConfirmed}" />
				
			</Alive.SwipeActionPanel>

		The button has a red color by default, and fades into yellow following the confirmation animation.
		You can customize this gradient using the GradientStartColor and GradientEndColor properties.

		Tip: Alive provides a set of default gradients, as seen in the example below.


			<Alive.SwipeActionPanel GradientStartColor="Alive.Gradient1.StartColor" GradientEndColor="Alive.Gradient1.EndColor">


		By default, the confirmation message is hidden after a short duration.
		This behavior can be disabled using the StayOpen property.
		It is useful for preventing the confirmation animation from playing at the same time as a RemovingAnimation,
		for cases where the button causes its containing element to be removed from a list.


			<Panel>
				<Alive.SwipeActionPanel StayOpen="true">
					<!-- Content -->
				</Alive.SwipeActionPanel>

				<RemovingAnimation>
					<Scale Factor="0" Duration=".4" />
				</RemovingAnimation>
			</Panel>
	*/
	public partial class SwipeActionPanel {}
}
