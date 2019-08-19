using Uno;

namespace Fuse.Triggers.Actions
{
	public enum TransitionStateType
	{
		Next,
	}


	/**
		@mount Trigger Actions

		An action that controls state of a @StateGroup.

		## Example
		The following example displays a red panel that will turn its color in green when clicked.

			<Panel ux:Name="thePanel" Width="100" Height="100">
				<StateGroup ux:Name="stateGroup">
					<State ux:Name="redState">
						<Change thePanel.Color="#f00" Duration="0.2"/>
					</State>
					<State ux:Name="greenState">
						<Change thePanel.Color="#0f0" Duration="0.2"/>
					</State>
				</StateGroup>

				<Clicked>
					<TransitionState Value="greenState" Target="stateGroup" />
				</Clicked>
			</Panel>
	*/
	public class TransitionState : TriggerAction
	{
		/** StateGroup to be be transitioned **/
		public StateGroup Target { get; set; }

		public TransitionStateType Type { get; set; }

		/** Explicit target state to transition to  **/
		public State Value { get; set; }

		protected override void Perform(Node target)
		{
			var t = Target;
			var s = Value;

			if (t == null)
			{
				Fuse.Diagnostics.UserError( "Missing `Target`", this );
				return;
			}

			if (s != null) {
				t.Goto(s);
				return;
			}

			switch (Type)
			{
				case TransitionStateType.Next:
					t.GotoNextState();
					return;
			}

			Fuse.Diagnostics.UserWarning( "Provide `Value` or `Type`", this );
		}
	}
}
