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
				Assert.AreEqual( "one/a", p.router.GetCurrentRoute().Format() );

				p.gotoNext.Pulse();
				root.StepFrame();
				Assert.AreEqual( "two", p.router.GetCurrentRoute().Format() );
				
				p.gotoParams.Pulse();
				root.StepFrame();
				Assert.AreEqual( "three?{\"id\":12}", p.router.GetCurrentRoute().Format() );
				
				p.gotoInner.Pulse();
				root.StepFrame();
				Assert.AreEqual( "four?{\"id\":13}/inner?{\"a\":1,\"b\":2}", p.router.GetCurrentRoute().Format() );
				
 				p.gotoEmpty.Pulse();
 				root.StepFrame();
 				Assert.AreEqual( "one/b", p.router.GetCurrentRoute().Format() );
			}
		}
		
		[Test]
		public void DynamicPath()
		{
			Router.TestClearMasterRoute();
			var p =new UX.RouterModify.DynamicPath();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual( "one", p.router.GetCurrentRoute().Format() );

				p.gotoNext.Pulse();
				root.StepFrameJS();
				Assert.AreEqual( "two?{\"id\":12}", p.router.GetCurrentRoute().Format() );
				
				p.gotoParam.Pulse();
				root.StepFrameJS();
				Assert.AreEqual( "three?{\"id\":22}", p.router.GetCurrentRoute().Format() );
				
				p.gotoProp.Pulse();
				root.StepFrame();
				Assert.AreEqual( "one?{\"id\":8}", p.router.GetCurrentRoute().Format() );
			}
		}
	}
}
