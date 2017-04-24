using Uno;
using Uno.UX;

using Fuse;
using Fuse.Triggers.Actions;

namespace FuseTest
{
	public class CountAction: TriggerAction
	{
		public int PerformedCount { get; private set; }

		protected override void Perform(Node target)
		{
			PerformedCount += 1;
		}
		
		public void Reset()
		{
			PerformedCount = 0;
		}
	}
}