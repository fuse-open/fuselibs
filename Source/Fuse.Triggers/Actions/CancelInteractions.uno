using Uno;

namespace Fuse.Triggers.Actions
{
	/**
		@mount Trigger Actions
	*/
	public class CancelInteractions : TriggerAction
	{
		public Visual Target { get; set; }
		
		protected override void Perform(Node target)
		{
			var t = Target ?? target.FindByType<Visual>();
			if (t != null)
				t.CancelInteractions();
		}
	}
}