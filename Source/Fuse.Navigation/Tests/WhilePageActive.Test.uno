using Uno;
using Uno.Testing;

using FuseTest;

namespace Fuse.Navigation.Test
{
	public class WhilePageActiveTest : TestBase
	{
		[Test]
		public void Basic()
		{
			var p = new UX.WhilePageActive.Basic();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(1,TriggerProgress(p.W1));
				Assert.AreEqual(1,TriggerProgress(p.W2));
				Assert.AreEqual(0,TriggerProgress(p.W3));

				p.Active = p.two;
				root.StepFrame(); //fudge for motion delayed start
				root.StepFrame(0.5f);
				Assert.AreEqual(0,TriggerProgress(p.W1));
				Assert.AreEqual(0,TriggerProgress(p.W2));
				Assert.AreEqual(1,TriggerProgress(p.W3));

				root.StepFrame(0.5f);
				Assert.AreEqual(1,TriggerProgress(p.W1));
				Assert.AreEqual(0,TriggerProgress(p.W2));
				Assert.AreEqual(0,TriggerProgress(p.W3));
			}
		}
	}
}