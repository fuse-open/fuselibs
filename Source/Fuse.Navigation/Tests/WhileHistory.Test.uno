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
			Router.TestClearMasterRoute();
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
		
	}
}
