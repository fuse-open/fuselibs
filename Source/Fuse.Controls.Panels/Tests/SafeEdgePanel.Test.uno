using Uno;
using Uno.Testing;

using FuseTest;

namespace Fuse.Controls.Panels.Test
{
	extern(!iOS && !Android)
	public class SafeEdgePanelTest : TestBase
	{
		[Test]
		public void Basic()
		{
			var p = new UX.SafeEdgePanel.Basic();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( float4(0), p.a.Padding );
				Assert.AreEqual( float4(0,0,10,5), p.b.Padding );
				Assert.AreEqual( float4(5,5,5,5), p.c.Padding );

				root.SetSafeMargins( float4(1,5,10,15) );
				root.StepFrame();
				Assert.AreEqual( float4(1,5,10,0), p.a.Padding );
				Assert.AreEqual( float4(0,0,20,20), p.b.Padding );
				Assert.AreEqual( float4(5,5,5,15), p.c.Padding );
			}
		}
	}
}
