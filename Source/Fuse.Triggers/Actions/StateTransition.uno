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
			if (t == null)
			{
				Fuse.Diagnostics.UserError( "Missing `Target`", this );
				return;
			}
			
			switch (Type)
			{
				case TransitionStateType.Next:
					t.GotoNextState();
					break;
			}
		}
	}
}