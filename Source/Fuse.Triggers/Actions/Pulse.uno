using Uno;

namespace Fuse.Triggers.Actions
{
	/** Momentarily triggers a @WhileTrue, @WhileFalse or @Timeline.

		# Example
		In this example, a pulse activated by pressing a `Button` scales the button by 1.5 over 0.2 seconds, then scales it back to 1 over the same duration.

			<Button Text="Pulse">
				<WhileTrue ux:Name="pulseMe" Value="false">
					<Scale Factor="1.5" Duration="0.2" />
				</WhileTrue>

				<Clicked>
					<Pulse Target="pulseMe" />
				</Clicked>
			</Button>

	*/
	public class Pulse : TriggerAction
	{
		public IPulseTrigger Target { get; set; }
		
		protected override void Perform(Node target)
		{
			var t = Target;
			if (t != null)
				t.Pulse();
		}
	}

	/**
		@mount Trigger Actions
	*/
	public class PulseBackward : TriggerAction
	{
		public Timeline Target { get; set; }
		
		protected override void Perform(Node target)
		{
			var t = Target;
			if (t != null)
				t.PulseBackward();
		}
	}

	/**
		@mount Trigger Actions
	*/
	public class PulseForward : TriggerAction
	{
		public Timeline Target { get; set; }
		
		protected override void Perform(Node target)
		{
			var t = Target;
			if (t != null)
				t.PulseForward();
		}
	}
	
}
