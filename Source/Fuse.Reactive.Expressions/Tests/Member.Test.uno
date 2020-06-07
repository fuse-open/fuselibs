using Uno;
using Uno.UX;
using Uno.Testing;

using FuseTest;

namespace Fuse.Reactive.Test
{
	public class MemberTest : TestBase
	{
		[Test]
		public void Basic()
		{
			var p = new UX.Member.Basic();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual(3, p.sv.Value);
				Assert.AreEqual(4, p.siv.Value);
				Assert.AreEqual(5, p.dv.Value);
				Assert.AreEqual(6, p.div.Value);
				Assert.AreEqual(2, p.so.Value);
				Assert.AreEqual(3, p.asv.Value);
				Assert.AreEqual(4, p.asiv.Value);
				Assert.AreEqual(5, p.adv.Value);
				Assert.AreEqual(6, p.adiv.Value);

				p.callStep1.Perform();
				root.StepFrameJS();
				Assert.AreEqual(12, p.so.Value);
				Assert.AreEqual(15, p.dv.Value);
				Assert.AreEqual(16, p.div.Value);
				Assert.AreEqual(15, p.adv.Value);
				Assert.AreEqual(16, p.adiv.Value);
			}
		}
	}
}
