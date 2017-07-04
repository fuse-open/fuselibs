using Uno;
using Uno.Compiler;
using Uno.Testing;
using Uno.UX;

using Fuse;

using FuseTest;

namespace Fuse.Test
{
	public class VisualTest : TestBase
	{
		[Test]
		public void IsFlat()
		{
			var p = new UX.VisualIsFlat();
			var r = TestRootPanel.CreateWithChild(p);
			
			Assert.IsTrue(p.A.IsFlat);
			
			Assert.IsFalse(p.B.IsFlat);
			Assert.IsFalse(p.B.IsLocalFlat);
			//Assert.IsTrue(p.B.AreChildrenFlat);
			
			Assert.IsFalse(p.C.IsFlat);
			Assert.IsTrue(p.C.IsLocalFlat);
			//Assert.IsFalse(p.C.AreChildrenFlat);
			
			Assert.IsFalse(p.D.IsFlat);
			Assert.IsFalse(p.E.IsLocalFlat);
			p.R1.DegreesX = 0;
			Assert.IsTrue(p.D.IsFlat);
			Assert.IsTrue(p.E.IsLocalFlat);
			
			Assert.IsTrue(p.F.IsFlat);
		}
		
		[Test]
		/*
			Tests an invalidation issue https://github.com/fusetools/fuselibs/issues/2318
		*/
		public void HitTestBounds2318()
		{
			var p = new UX.VisualHitTestBounds();
			var r = TestRootPanel.CreateWithChild(p,int2(1000,800));
			
			Assert.IsTrue(p.B.HitTestBounds.IsEmpty);
			p.Enabler.Value = true;
			r.IncrementFrame(); //for layout
			Assert.AreEqual(float3(400,300,0), p.B.HitTestBounds.AxisMin);
			Assert.AreEqual(float3(600,500,0), p.B.HitTestBounds.AxisMax);
			p.Enabler.Value = false;
			r.IncrementFrame(); //for layout
			Assert.IsTrue(p.B.HitTestBounds.IsEmpty);
		}
	}
}
