using Uno;
using Uno.Compiler;
using Uno.Testing;

using FuseTest;

namespace Fuse.Elements.Test
{
	public class BringIntoViewTest : TestBase
	{
		[Test]
		public void Basic()
		{
			var p = new global::UX.BringIntoView.Basic();
			using (var root = TestRootPanel.CreateWithChild(p,int2(100)))
			{
				p.t1.Pulse();
				root.StepFrame(5); //for scroll anim
				Assert.AreEqual(275, p.ScrollPosition.Y, 1e-2);
				
				p.t2.Pulse();
				root.StepFrame(5); //for scroll anim
				Assert.AreEqual(580, p.ScrollPosition.Y, 1e-2);
			}
		}
	}
}
