using Uno;
using Uno.Collections;
using Uno.Compiler;
using Uno.Testing;
using Uno.UX;

using Fuse;

using FuseTest;

namespace Fuse.Test
{
	public class ZOrderTestPanel: Fuse.Controls.Panel
	{
		internal int InvalidatedCount;
		protected override void OnZOrderInvalidated() 
		{
			InvalidatedCount++;
		}
	}

	public class ZOrderTestChildPanel: Fuse.Controls.Panel
	{
		protected override void OnZOrderInvalidated() 
		{
			throw new Exception("This shouldn't happen");
		}
	}

	public class VisualTest : TestBase
	{
		
		[Test]
		public void ZOrderChanged()
		{
			var p = new UX.ZOrderChanged();
			using (var r = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(3, p.InvalidatedCount);
				p.toggle.Value = true;
				r.StepFrame();
				Assert.AreEqual(4, p.InvalidatedCount);

				p.BringToFront(p.p3);
				Assert.AreEqual(5, p.InvalidatedCount);
				p.BringToFront(p.p3); // shouldn't fire the event, it's already in front
				Assert.AreEqual(5, p.InvalidatedCount);

				p.p1.ZOffset = 3;
				Assert.AreEqual(6, p.InvalidatedCount);
				p.p1.ZOffset = 3; // shouldn't fire the event, the same z-order
				Assert.AreEqual(6, p.InvalidatedCount);

				p.p2.Layer = Layer.Background;
				Assert.AreEqual(7, p.InvalidatedCount);
				p.p2.Layer = Layer.Background;
				Assert.AreEqual(7, p.InvalidatedCount);
			}
		}

		[Test]
		public void IsFlat()
		{
			var p = new UX.VisualIsFlat();
			using (var r = TestRootPanel.CreateWithChild(p))
			{
				Assert.IsTrue(p.A.IsFlat);
				
				Assert.IsFalse(p.B.IsFlat);
				Assert.IsFalse(p.B.IsLocalFlat);
				Assert.IsTrue(p.B.AreChildrenFlat);
				
				Assert.IsFalse(p.C.IsFlat);
				Assert.IsTrue(p.C.IsLocalFlat);
				Assert.IsFalse(p.C.AreChildrenFlat);
				
				Assert.IsFalse(p.D.IsFlat);
				Assert.IsFalse(p.E.IsLocalFlat);
				p.R1.DegreesX = 0;
				Assert.IsTrue(p.D.IsFlat);
				Assert.IsTrue(p.E.IsLocalFlat);
				
				Assert.IsTrue(p.F.IsFlat);
			}
		}
		
		[Test]
		/*
			Tests an invalidation issue https://github.com/fusetools/fuselibs/issues/2318
		*/
		public void HitTestBounds2318()
		{
			var p = new UX.VisualHitTestBounds();
			using (var r = TestRootPanel.CreateWithChild(p,int2(1000,800)))
			{
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
}
