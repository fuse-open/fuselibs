using Uno;
using Uno.Testing;

using FuseTest;

namespace Fuse.Controls.Primitives.Test
{
	public class EllipseTest : TestBase
	{
		[Test]
		[extern(MSVC) Ignore("no surface backend")]
		//just some spot tests for sanity
		public void HitTest()
		{
			var p = new UX.Ellipse.HitTest();
			using (var root = TestRootPanel.CreateWithChild(p,int2(300,200)))
			{
				Assert.AreEqual(p.a, p.GetHitWindowPoint( float2(50,50)));
				Assert.AreEqual(null, p.GetHitWindowPoint( float2(21,15)));
				Assert.AreEqual(p.a, p.GetHitWindowPoint( float2(147,89)));
				
				Assert.AreEqual(p.b, p.GetHitWindowPoint( float2(0,100) + float2(52,88)));
				Assert.AreEqual(null, p.GetHitWindowPoint( float2(0,100) + float2(52,95)));
				Assert.AreEqual(p.b, p.GetHitWindowPoint( float2(0,100) + float2(152,51)));
				Assert.AreEqual(null, p.GetHitWindowPoint( float2(0,100) + float2(152,49)));
				
				Assert.AreEqual(p.c, p.GetHitWindowPoint( float2(200,0) + float2(78,22)));
				Assert.AreEqual(null, p.GetHitWindowPoint( float2(200,0) + float2(83,22)));
				Assert.AreEqual(null, p.GetHitWindowPoint( float2(200,0) + float2(49,22)));
				Assert.AreEqual(null, p.GetHitWindowPoint( float2(200,0) + float2(55,101)));
				Assert.AreEqual(p.c, p.GetHitWindowPoint( float2(200,0) + float2(51,99)));
			}
		}
	}
}
