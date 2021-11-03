namespace Alive
{
	/**
		Reveals a button when the user swipes left on its contents.
		A confirmation message is shown when the button is tapped.

		```xml
		<Panel ux:Name="ParentPanel" Color="#ccc">
      <Alive.SwipeActionPanel ButtonText="Do nothing"
                              ConfirmationText="And thus, nothing was done"
                              Height="80">
  		    <Panel ux:Name="BodyPanel" Color="#fff">
            <Text Value="Swipe me left" Alignment="Center"/>
          </Panel>
  		</Alive.SwipeActionPanel>
    </Panel>
		```

		![actionButton](../../docs/media/alive/SwipeActionPanel.gif)

		When the button is tapped, this component will raise a UserEvent named Alive.SwipeActionConfirmed.
		You can handle this event using the Alive.SwipeActionConfirmed trigger.

		```xml
		<JavaScript>
      var Observable = require("FuseJS/Observable");
      var bodyPanelText = Observable("Swipe me left");

      exports.bodyPanelText = bodyPanelText;
      exports.onConfirmed = function() {
				bodyPanelText.value = "Action was confirmed!";
			};

		</JavaScript>

    <Panel ux:Name="ParentPanel" Color="#ccc">
      <Alive.SwipeActionPanel ButtonText="Do nothing"
                              ConfirmationText="Congratulations!"
                              Height="80">
          <Alive.SwipeActionConfirmed Handler="{onConfirmed}" />

  		    <Panel ux:Name="BodyPanel" Color="#fff">
            <Text Value="{bodyPanelText}" Alignment="Center"/>
          </Panel>
  		</Alive.SwipeActionPanel>
    </Panel>
		```

		![actionButton](../../docs/media/alive/SwipeActionPanelConfirmation.gif)

		The button has a red color by default, and fades into yellow following the confirmation animation.
		You can customize this gradient using the GradientStartColor and GradientEndColor properties.

		Tip: Alive provides a set of default gradients, as seen in the example below.

		```xml
			<Alive.SwipeActionPanel GradientStartColor="Alive.Gradient1.StartColor" GradientEndColor="Alive.Gradient1.EndColor">
		```

		By default, the confirmation message is hidden after a short duration.
		This behavior can be disabled using the StayOpen property.
		It is useful for preventing the confirmation animation from playing at the same time as a RemovingAnimation,
		for cases where the button causes its containing element to be removed from a list.

		```xml
			<Panel>
				<Alive.SwipeActionPanel StayOpen="true">
					<!-- Content -->
				</Alive.SwipeActionPanel>

				<RemovingAnimation>
					<Scale Factor="0" Duration=".4" />
				</RemovingAnimation>
			</Panel>
		```

		![actionButton](../../docs/media/alive/SwipeActionPanelConfirmationStayOpen.gif)

	*/
	public partial class SwipeActionPanel {}
}
