using Uno;

namespace Fuse.Triggers.Actions
{
	public enum TransitionStateType
	{
		Next,
	}

	/**
		@mount Trigger Actions
	*/
	public class TransitionState : TriggerAction
	{
		public StateGroup Target { get; set; }
	
		public TransitionStateType Type { get; set; }
		
		protected override void Perform(Node target)
		{
			var t = Target;
			switch (Type)
			{
				case TransitionStateType.Next:
					t.GotoNextState();
					break;
			}
		}
	}
}