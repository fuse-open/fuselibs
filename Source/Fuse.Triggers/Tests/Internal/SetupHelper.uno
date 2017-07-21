using Uno;
using Fuse;
using Fuse.Elements;
using Fuse.Controls;
using Fuse.Triggers;
using Fuse.Triggers.Actions;
using FuseTest;

namespace Fuse.Triggers.Test
{
	public class SetupHelper
	{
		public static SetupEntity Setup(TestRootPanel root, Element control, Trigger trigger, bool addControlToPanel = true)
		{
			//this should all happen at once in terms of rooting (vital to the trigger actions)
			var capture = Node.CaptureRooting();
			
			var se = AddAction(control, trigger);
			var panel = new Panel();
			se.Panel = panel;

			if (addControlToPanel)
				panel.Children.Add(control);

			root.Children.Add(panel);
			root.Layout(int2(200));

			Node.ReleaseRooting(capture);
			root.PumpDeferred();
			return se;
		}
		
		public static SetupEntity AddAction(Element control, Trigger trigger)
		{
			var forwardTriggerAction = new FuseTest.CountAction();
			forwardTriggerAction.When = TriggerWhen.Forward;

			var backwardTriggerAction = new FuseTest.CountAction();
			backwardTriggerAction.When = TriggerWhen.Backward;

			trigger.Actions.Add(forwardTriggerAction);
			trigger.Actions.Add(backwardTriggerAction);

			control.Children.Add(trigger);

			return new SetupEntity(control, null, forwardTriggerAction, backwardTriggerAction);
		}
	}
}