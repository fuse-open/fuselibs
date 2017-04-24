using Uno;
using Uno.UX;
using Fuse.Controls;
using Fuse.Elements;
using Fuse.Input;
using Fuse.Triggers.Actions;

namespace Fuse.Triggers.Test
{
	public class NavigationSetupEntity
	{
		public FuseTest.CountAction ActivatedTriggerForwardAction { get; set; }

		public FuseTest.CountAction ActivatedTriggerBackwardAction { get; set; }

		public FuseTest.CountAction EnterTriggerForwardAction { get; set; }

		public FuseTest.CountAction EnterTriggerBackwardAction { get; set; }

		public FuseTest.CountAction ExitTriggerForwardAction { get; set; }

		public FuseTest.CountAction ExitTriggerBackwardAction { get; set; }

		public Page Page { get; set; }

		public NavigationSetupEntity(Page page, FuseTest.CountAction activatedTriggerForwardAction, FuseTest.CountAction activatedTriggerBackwardAction,
									  FuseTest.CountAction enterTriggerForwardAction, FuseTest.CountAction enterTriggerBackwardAction,
									  FuseTest.CountAction exitTriggerForwardAction, FuseTest.CountAction exitTriggerBackwardAction)
		{
			Page = page;
			ActivatedTriggerForwardAction = activatedTriggerForwardAction;
			ActivatedTriggerBackwardAction = activatedTriggerBackwardAction;
			EnterTriggerForwardAction = enterTriggerForwardAction;
			EnterTriggerBackwardAction = enterTriggerBackwardAction;
			ExitTriggerForwardAction = exitTriggerForwardAction;
			ExitTriggerBackwardAction = exitTriggerBackwardAction;
		}
		
		public void Reset()
		{	
			ActivatedTriggerForwardAction.Reset();
			ActivatedTriggerBackwardAction.Reset();
			EnterTriggerForwardAction.Reset();
			EnterTriggerBackwardAction.Reset();
			ExitTriggerForwardAction.Reset();
			ExitTriggerBackwardAction.Reset();
		}
		
	}
}