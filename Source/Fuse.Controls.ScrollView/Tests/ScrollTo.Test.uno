using Uno;
using Uno.UX;
using Uno.Testing;

using FuseTest;

using Fuse.Elements;

namespace Fuse.Controls.ScrollToTest
{
	public class ScrollToTest : TestBase
	{
		[Test]
		public void Basic()
		{
			var s = new UX.ScrollTo.Basic();
			using (var root = TestRootPanel.CreateWithChild(s,int2(500)))
			{
				s.stA.Pulse();
				root.StepFrame(5); //stabilize animation
				Assert.AreEqual(300,s.ScrollPosition.Y);
				
				s.stB.Pulse();
				root.StepFrame(5); //stabilize animation
				Assert.AreEqual(750,s.ScrollPosition.Y);
			}
		}
		
		[Test]
		public void Target()
		{
			var p = new UX.ScrollTo.Target();
			using (var root = TestRootPanel.CreateWithChild(p,int2(500)))
			{
				p.stA.Pulse();
				root.StepFrame(5); //stabilize animation
				Assert.AreEqual(300,p.s.ScrollPosition.Y);
				
				p.stB.Pulse();
				//no need to wait, was seek
				root.PumpDeferred();
				Assert.AreEqual(750,p.s.ScrollPosition.Y);
			}
		}
	}
}
