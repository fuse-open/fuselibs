using Uno;
using Uno.Testing;

using FuseTest;

namespace Fuse.Controls.Test
{
	public class ViewportTest : TestBase
	{
		struct HitTestPoint {
			public int2 Point;
			public ClickPanel Panel;
		}

		HitTestPoint[] GetHitTestPoints(UX.ViewportHitTest p)
		{
			return new HitTestPoint[] {
				new HitTestPoint { Point = int2(107,114), Panel = p.Q.A },
				new HitTestPoint { Point = int2(421,164), Panel = p.Q.B },
				new HitTestPoint { Point = int2(66,326), Panel = p.Q.C },
				new HitTestPoint { Point = int2(448,220), Panel = p.Q.D },
				new HitTestPoint { Point = int2(729,63), Panel = p.R.A },
				new HitTestPoint { Point = int2(787,110), Panel = p.R.B },
				new HitTestPoint { Point = int2(455,413), Panel = p.R.C },
				new HitTestPoint { Point = int2(960,226), Panel = p.R.D },
				new HitTestPoint { Point = int2(72,515), Panel = p.S.A },
				new HitTestPoint { Point = int2(265,513), Panel = p.S.B },
				new HitTestPoint { Point = int2(114,725), Panel = p.S.C },
				new HitTestPoint { Point = int2(288,794), Panel = p.S.C },
				new HitTestPoint { Point = int2(399,629), Panel = p.S.D },
				new HitTestPoint { Point = int2(733,584), Panel = p.T.A },
				new HitTestPoint { Point = int2(782,581), Panel = p.T.B },
				new HitTestPoint { Point = int2(734,629), Panel = p.T.C },
				new HitTestPoint { Point = int2(757,634), Panel = p.T.D },
				new HitTestPoint { Point = int2(960,639), Panel = p.T.D },
			};
		}

		[Test]
		/*
			This checks the correctness of the hit testing.  The UX represents a variety of viewport layering.
			The points are selected by hand, refer to `Tests/Sandbox/ViewportHitTest` which uses the same
			UX file. Note, they aren't just random: several key if conditions in the code, and translations are
			tested.
		*/
		public void HitTest()
		{
			var p = new UX.ViewportHitTest();
			using (var r = TestRootPanel.CreateWithChild(p, int2(1000)))
			{
				foreach (var hitTestPoint in GetHitTestPoints(p))
				{
					//root-level testing, used by uncapture input
					var hitResult = Fuse.Input.HitTestHelpers.HitTestNearest(r, hitTestPoint.Point);
					Assert.AreEqual(hitTestPoint.Panel, hitResult.HitObject);

					//capture level routing
					//so longer as there is no overlap in the tests looking in each parent should produce the same result
					Visual start = hitTestPoint.Panel;
					while (start != null)
					{
						var hitVisual = start.GetHitWindowPoint(hitTestPoint.Point);
						Assert.AreEqual(hitTestPoint.Panel, hitVisual);
						start = start.Parent;
					}
				}
			}
		}

		[Test]
		/*
			The colors of points tested in HitTest should also be known, this tests them. A separate test
			to keep the drawing stuff isolated from the pure algorithm stuff.
		*/
		public void DrawTest()
		{
			var p = new UX.ViewportHitTest();
			using (var r = TestRootPanel.CreateWithChild(p, int2(1000)))
			using (var fb = r.CaptureDraw())
			{
				foreach (var hitTestPoint in GetHitTestPoints(p))
					fb.AssertPixel(hitTestPoint.Panel.Color, hitTestPoint.Point);
			}
		}

		[Test]
		/* 
			Viewport should be cacheable. This quick test tests for that. It's kept fairly light since the actual
			caching heuristic also plays a role here.
		*/
		public void Cache()
		{
			var p = new UX.ViewportCache();
			using (var r = TestRootPanel.CreateWithChild(p, int2(500)))
			{
				for (int i=0;i < 5; ++i)
					r.TestDraw();
				
				Assert.AreEqual(5,p.B.DrawCount);
				//Dependent on exact heuristic and can be changed, but certainly should be less than 5, probably 1 or 2
				Assert.AreEqual(1,p.A.DrawCount);
				Assert.AreEqual(1,p.C.DrawCount);
			}
		}
		
		[Test]
		/*
			Viewports can flatten their children.
		*/
		public void IsFlat()
		{
			var p = new UX.ViewportFlat();
			using (var r = TestRootPanel.CreateWithChild(p))
			{
				Assert.IsTrue(p.C.IsFlat);
				p.C.Mode = Fuse.Elements.ViewportMode.Disabled;
				Assert.IsFalse(p.C.IsFlat);
				p.R.DegreesX = 0;
				Assert.IsTrue(p.C.IsFlat);
			}
		}
	}
	
	public class MockViewport : Fuse.Elements.Viewport
	{
		public int DrawCount;
		protected override void DrawWithChildren(DrawContext dc)
		{
			base.DrawWithChildren(dc);
			DrawCount++;
		}
	}
}
