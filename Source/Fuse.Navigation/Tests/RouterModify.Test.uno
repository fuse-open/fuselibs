using Uno;
using Uno.Compiler;
using Uno.Testing;
using Uno.UX;

using FuseTest;

using Fuse.Elements;

namespace Fuse.Navigation.Test
{
	public class RouterModifyTest : TestBase
	{
		[Test]
		public void Bookmark()
		{
			Router.TestClearMasterRoute();
			var p = new UX.RouterModify.Bookmark();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual( "one", p.router.GetCurrentRoute().Format() );
				
				p.gotoNext.Pulse();
				root.StepFrame();
				Assert.AreEqual( "two?{}", p.router.GetCurrentRoute().Format() );
			}
		}
		
		[Test]
		public void Path()
		{
			Router.TestClearMasterRoute();
			var p =new UX.RouterModify.Path();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "one", p.router.GetCurrentRoute().Format() );
				debug_log " - - - - A";
				p.gotoNext.Pulse();
				debug_log " - - - - B";
				root.StepFrame();
				debug_log " - - - - C";
				Assert.AreEqual( "two", p.router.GetCurrentRoute().Format() );
			}
		}
	}
}
