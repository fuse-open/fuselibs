using Uno;
using Uno.Testing;

using FuseTest;

namespace Fuse.Navigation.Test
{
	public class WhileNavigatingTest : TestBase
	{
		[Test]
		public void Basic()
		{
			var p = new UX.WhileNavigatingTest();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(0, TriggerProgress(p.WN1));
				Assert.AreEqual(0, TriggerProgress(p.WN2));

				p.Nav.Active = p.P2;
				root.IncrementFrame();
				Assert.AreEqual(1, TriggerProgress(p.WN1));
				Assert.AreEqual(1, TriggerProgress(p.WN2));

				root.StepFrame(5); //stabilize
				Assert.AreEqual(0, TriggerProgress(p.WN1));
				Assert.AreEqual(0, TriggerProgress(p.WN2));
			}
		}
	}
}
