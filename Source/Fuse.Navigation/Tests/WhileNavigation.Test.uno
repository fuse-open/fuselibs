using Uno;
using Uno.Compiler;
using Uno.Testing;
using Uno.UX;

using FuseTest;

using Fuse.Elements;

namespace Fuse.Navigation.Test
{
	public class WhileNavigationTest : TestBase
	{
		[Test]
		public void WhileNavigationDeep()
		{
			var p = new UX.WhileNavigation.Deep();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(1,p.WA.Progress);
				Assert.AreEqual(0,p.WI.Progress);

				p.Step1.Perform();
				root.StepFrameJS();
				Assert.AreEqual(0,p.WA.Progress);
				Assert.AreEqual(1,p.WI.Progress);

				p.Step2.Perform();
				root.StepFrameJS();
				Assert.AreEqual(1,p.WA.Progress);
				Assert.AreEqual(0,p.WI.Progress);

				p.C1.Active = p.D2;
				root.StepFrame(1);
				Assert.AreEqual(0,p.WA.Progress);
				Assert.AreEqual(1,p.WI.Progress);
			}
		}

	}
}
