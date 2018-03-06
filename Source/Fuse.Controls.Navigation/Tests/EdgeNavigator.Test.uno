using Uno;
using Uno.Testing;

using Fuse.Navigation;

using FuseTest;

namespace Fuse.Controls.Test
{
	public class EdgeNavigatorTest : ModelTestBase
	{
		[Test]
		public void ModelPages()
		{
			var p = new UX.EdgeNavigator.ModelPages();
			using (var root = TestRootPanel.CreateWithChild(p, int2(1000)))
			{
				root.StepFrameJS();

				Assert.AreEqual( "Main", p.title.Value );
				Assert.AreEqual( "main", (string)p.nav.Active.Name );
				
				p.callGoLeft.Perform();
				root.StepFrameJS(5);
				Assert.AreEqual( "Left", p.title.Value );
				Assert.AreEqual( "left", (string)p.nav.Active.Name );
				
				root.PointerPress( float2(500));
				root.PointerRelease();
				root.StepFrame(5);
				root.StepFrameJS();
				Assert.AreEqual( "Main", p.title.Value );
				Assert.AreEqual( "main", (string)p.nav.Active.Name );
				
				root.PointerSwipe( float2(999,100), float2(900,100) );
				root.StepFrame(5);
				root.StepFrameJS();
				Assert.AreEqual( "Right", p.title.Value );
				Assert.AreEqual( "RightPage", (string)p.nav.Active.Name );
				
				p.goBack.Pulse();
				root.StepFrame(5);
				root.StepFrameJS();
				Assert.AreEqual( "Main", p.title.Value );
				Assert.AreEqual( "main", (string)p.nav.Active.Name );
			}
		}
		
		[Test]
		public void NavigateToggle()
		{
			var p = new UX.EdgeNavigator.NavigateToggle();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( p.main, p.nav.Active );
				
				p.toggleLeft.Pulse();
				root.StepFrame(5);
				Assert.AreEqual( p.left, p.nav.Active );
				
				p.toggleElse.Pulse();
				root.StepFrame(5);
				Assert.AreEqual( p.main, p.nav.Active );
			}
		}
	}
}
