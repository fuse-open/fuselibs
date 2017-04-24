using Uno;
using Uno.UX;
using Fuse.Controls;
using Fuse.Elements;
using Fuse.Input;
using Fuse.Triggers.Actions;

namespace Fuse.Triggers.Test
{
	public class SetupEntity
	{
		public FuseTest.CountAction ForwardAction { get; set; }

		public FuseTest.CountAction BackwardAction { get; set; }

		public Element Control { get; set; }

		public Panel Panel { get; set; }

		public SetupEntity(Element control, Panel panel, FuseTest.CountAction forwardAction, FuseTest.CountAction backwardAction)
		{
			Control = control;
			Panel = panel;
			ForwardAction = forwardAction;
			BackwardAction = backwardAction;
		}
	}
}