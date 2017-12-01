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
		public void IsFlatBasic()
		{
			var p = new UX.Visual.IsFlatBasic();
			using (var r = TestRootPanel.CreateWithChild(p))
			{
				Assert.IsTrue(p.A.IsFlat);
				
				Assert.IsFalse(p.B.IsFlat);
				Assert.IsFalse(p.B.IsLocalFlat);
				
				Assert.IsFalse(p.C.IsFlat);
				Assert.IsTrue(p.C.IsLocalFlat);
				
				Assert.IsFalse(p.D.IsFlat);
				Assert.IsFalse(p.E.IsLocalFlat);
				p.R1.DegreesX = 0;
				Assert.IsTrue(p.D.IsFlat);
				Assert.IsTrue(p.E.IsLocalFlat);
				
				Assert.IsTrue(p.F.IsFlat);
			}
		}
		
		[Test]
		public void IsFlatDynamic()
		{
			var p = new UX.Visual.IsFlatDynamic();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.IsTrue(p.A.IsFlat);
				Assert.IsTrue(p.A.IsLocalFlat);
				Assert.IsTrue(p.B.IsFlat);
				Assert.IsTrue(p.C.IsFlat);
				
				p.RB.DegreesX = 5;
				Assert.IsFalse(p.A.IsFlat);
				Assert.IsTrue(p.A.IsLocalFlat);
				Assert.IsFalse(p.B.IsFlat);
				Assert.IsTrue(p.C.IsFlat);
				
				p.RC.DegreesY = 5;
				Assert.IsFalse(p.A.IsFlat);
				Assert.IsTrue(p.A.IsLocalFlat);
				Assert.IsFalse(p.B.IsFlat);
				Assert.IsFalse(p.C.IsFlat);
				
				p.RB.DegreesX = 0;
				Assert.IsFalse(p.A.IsFlat);
				Assert.IsTrue(p.A.IsLocalFlat);
				Assert.IsTrue(p.B.IsFlat);
				Assert.IsFalse(p.C.IsFlat);
				
				p.RC.DegreesY = 0;
				Assert.IsTrue(p.A.IsFlat);
				Assert.IsTrue(p.A.IsLocalFlat);
				Assert.IsTrue(p.B.IsFlat);
				Assert.IsTrue(p.C.IsFlat);
			}
		}
		
		[Test]
		public void IsFlatRooting()
		{
			var p = new UX.Visual.IsFlatRooting();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.IsTrue(p.A.IsFlat);
				Assert.IsTrue(p.B.IsFlat);
				Assert.IsTrue(p.C.IsFlat);
				
				p.WB.Value = true;
				root.PumpDeferred();
				Assert.IsFalse(p.A.IsFlat);
				Assert.IsTrue(p.A.IsLocalFlat);
				Assert.IsFalse(p.B.IsFlat);
				Assert.IsTrue(p.C.IsFlat);
				
				p.WB.Value = false;
				p.WC.Value = true;
				root.PumpDeferred();
				Assert.IsFalse(p.A.IsFlat);
				Assert.IsTrue(p.A.IsLocalFlat);
				Assert.IsTrue(p.B.IsFlat);
				Assert.IsFalse(p.C.IsFlat);
				
				p.WC.Value = false;
				root.PumpDeferred();
				Assert.IsTrue(p.A.IsFlat);
				Assert.IsTrue(p.B.IsFlat);
				Assert.IsTrue(p.C.IsFlat);
			}
		}
		
		[Test]
		public void IsFlatAlternate()
		{
			var p = new UX.Visual.IsFlatAlternate();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.IsTrue(p.A.IsFlat);
				Assert.IsTrue(p.C.IsFlat);
				
				p.alt.IsEnabled = true;
				root.PumpDeferred();
				Assert.IsFalse(p.A.IsFlat);
				Assert.IsTrue(p.B.IsFlat);
				Assert.IsFalse(p.C.IsFlat);
				
				p.alt.IsEnabled = false;
				root.PumpDeferred();
				Assert.IsTrue(p.A.IsFlat);
				Assert.IsTrue(p.B.IsFlat);
				Assert.IsTrue(p.C.IsFlat);
			}
		}
		
		[Test]
		public void IsFlatMultiple()
		{
			var p = new UX.Visual.IsFlatMultiple();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameDeferred();
				var C = p.FindNodeByName("C") as Visual;
				var D = p.FindNodeByName("D") as Visual;
				Assert.IsFalse(p.A.IsFlat);
				Assert.IsTrue(p.B.IsFlat);
				Assert.IsFalse(C.IsFlat);
				Assert.IsFalse(D.IsFlat);
				
 				C.FirstChild<Translation>().Z = 0;
 				D.FirstChild<Translation>().Z = 0;
 				Assert.IsTrue(p.A.IsFlat);
 				Assert.IsTrue(p.B.IsFlat);
 				Assert.IsTrue(C.IsFlat);
 				Assert.IsTrue(D.IsFlat);
 				
 				p.TB.Z = -1;
 				Assert.IsFalse(p.A.IsFlat);
 				Assert.IsFalse(p.B.IsFlat);
 				
 				p.RB.DegreesY = 1;
 				p.TB.Z = 0;
 				Assert.IsFalse(p.A.IsFlat);
 				Assert.IsFalse(p.B.IsFlat);
 				
 				p.RB.DegreesY = 0;
 				Assert.IsTrue(p.A.IsFlat);
 				Assert.IsTrue(p.B.IsFlat);
			}
		}
		
		[Test]
		public void IsFlatViewport()
		{
			var p = new UX.Visual.IsFlatViewport();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.IsTrue(p.IsFlat);
				Assert.IsTrue(p.V.IsFlat);
				Assert.IsFalse(p.B.IsFlat);
				
				p.RV.DegreesX = 5;
				Assert.IsFalse(p.IsFlat);
				Assert.IsFalse(p.V.IsFlat);
				Assert.IsFalse(p.B.IsFlat);
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

		[Test]
		public void ChildrenClear()
		{
			var p = new UX.Visual.ChildrenClear();
			using (var r = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(2, p.ParentA.Children.Count);
				p.ParentA.Children.Clear();
				Assert.AreEqual(0, p.ParentA.Children.Count);

				p.ParentB.Children.Add(p.ChildA);
				p.ParentB.Children.Add(p.ChildB);
				Assert.AreEqual(2, p.ParentB.Children.Count);
			}
		}
	}
}
