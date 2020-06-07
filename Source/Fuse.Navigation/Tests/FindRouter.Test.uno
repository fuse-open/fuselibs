using Uno;
using Uno.Testing;
using Uno.UX;

using FuseTest;

namespace Fuse.Navigation.Test
{
	public class FindRouter : TestBase
	{
		[Test]
		public void Basic()
		{
			var p = new UX.FindRouter.Basic();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(p.pc.Active, p.one);

				p.OneGo.Perform();
				root.StepFrameJS();
				Assert.AreEqual(p.pc.Active, p.two);

				p.TwoGo.Perform();
				root.StepFrameJS();
				Assert.AreEqual(p.pc.Active, p.one);
			}
		}
	}
}
