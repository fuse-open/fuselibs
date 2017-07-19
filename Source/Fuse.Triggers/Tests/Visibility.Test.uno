using Uno;
using Uno.Collections;
using Uno.Testing;

using Fuse.Elements;

using FuseTest;

namespace Fuse.Triggers.Test
{
	public class VisibilityTest : TestBase
	{
		[Test]
		public void Basic()
		{
			var p = new UX.Visibility.Basic();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( Visibility.Visible, p.a.Visibility );
				
				p.hide1.Pulse();
				root.PumpDeferred();
				Assert.AreEqual( Visibility.Hidden, p.a.Visibility );
				
				p.show1.Pulse();
				root.PumpDeferred();
				Assert.AreEqual( Visibility.Visible, p.a.Visibility );
				
				p.collapse1.Pulse();
				root.PumpDeferred();
				Assert.AreEqual( Visibility.Collapsed, p.a.Visibility );
				
				p.hide2.Pulse();
				root.PumpDeferred();
				Assert.AreEqual( Visibility.Hidden, p.a.Visibility );
				
				p.show2.Pulse();
				root.PumpDeferred();
				Assert.AreEqual( Visibility.Visible, p.a.Visibility );
				
				p.collapse2.Pulse();
				root.PumpDeferred();
				Assert.AreEqual( Visibility.Collapsed, p.a.Visibility );
			}
		}
	}
}