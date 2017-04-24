using Uno;
using Uno.Compiler;
using Uno.Testing;

using FuseTest;

namespace Fuse.Elements.Test
{
	public class ElementHitTest : TestBase
	{
		[Test]
		public void HitTestModeTest()
		{
			var p = new global::UX.Element.HitTestMode();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000)))
			{
				Assert.IsTrue(p.A.HitTestBounds.IsEmpty);
				
				p.B.HitTestMode = HitTestMode.Children;
				Assert.AreEqual(float3(400,450,0), p.A.HitTestBounds.AxisMin);
				Assert.AreEqual(float3(600,550,0), p.A.HitTestBounds.AxisMax);
				
				p.C.HitTestMode = HitTestMode.None;
				Assert.IsTrue(p.A.HitTestBounds.IsEmpty);
			}
		}
	}
}
