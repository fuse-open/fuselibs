using Uno;
using Uno.Compiler;
using Uno.Testing;
using Uno.UX;

using FuseTest;

using Fuse.Elements;

namespace Fuse.Navigation.Test
{
	public class WhileHistoryTest : TestBase
	{
		[Test]
		public void GoBackBehavior()
		{
			var p = new UX.WhileHistory.GoBackBehavior();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(0,p.wcb.Progress);

				p.Step1.Perform();
				root.StepFrameJS();
				Assert.AreEqual(1,p.wcb.Progress);

				p.Step2.Perform();
				root.StepFrameJS();
				Assert.AreEqual(0,p.wcb.Progress);
			}
		}

		[Test]
		public void GoBackRouter()
		{
			var p = new UX.WhileHistory.GoBackRouter();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(0,p.wcb.Progress);

				p.router.Push( new Route("b") );
				root.StepFrame();
				Assert.AreEqual(1, p.wcb.Progress);

				p.router.Push( new Route("c") );
				root.StepFrame();
				Assert.AreEqual(1, p.wcb.Progress);

				p.router.GoBack();
				root.StepFrame();
				Assert.AreEqual(1, p.wcb.Progress);

				p.router.GoBack();
				root.StepFrame();
				Assert.AreEqual(0, p.wcb.Progress);

				p.router.Push( new Route("b" ));
				root.StepFrame();
				Assert.AreEqual(1, p.wcb.Progress);

				p.router.Goto( new Route("c"));
				root.StepFrame();
				Assert.AreEqual(0, p.wcb.Progress);

				p.router.Push( new Route("c", null, new Route("i")));
				root.StepFrame();
				Assert.AreEqual(1, p.wcb.Progress);
			}
		}

	}
}
