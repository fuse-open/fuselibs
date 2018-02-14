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
				root.StepFrameJS(5);
				Assert.AreEqual( "Main", p.title.Value );
				Assert.AreEqual( "main", (string)p.nav.Active.Name );
			}
		}
	}
}
