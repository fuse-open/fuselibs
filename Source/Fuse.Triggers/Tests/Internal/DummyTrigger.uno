using Uno;
using Uno.UX;
using Fuse.Elements;
using Fuse.Input;

namespace Fuse.Triggers
{
	public class DummyTrigger : Trigger
	{
		public Node Target { get; set; }
		protected override void OnRooted() { Target = Parent; }
		protected override void OnUnrooted() { Target = null; }
	}
}
