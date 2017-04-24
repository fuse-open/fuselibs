using Uno;
using Uno.Testing;

using FuseTest;

namespace Fuse.Controls.Test
{
	public class ViewportTest : TestBase
	{
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
			_cRoot = TestRootPanel.CreateWithChild(p, int2(1000));
			TestBits(p, CheckHitTest);
		}
		
		void TestBits(UX.ViewportHitTest p, Action<float,float,ClickPanel> C)
		{
			C(107,114,p.Q.A);
			C(421,164,p.Q.B);
			C(66,326,p.Q.C);
			C(448,220,p.Q.D);
			
			C(729,63,p.R.A);
			C(787,110,p.R.B);
			C(455,413,p.R.C);
			C(960,226,p.R.D);
			
			C(72,515,p.S.A);
			C(265,513,p.S.B);
			C(114,725,p.S.C);
			C(288,794,p.S.C);
			C(399,629,p.S.D);
			
			C(733,584,p.T.A);
			C(782,581,p.T.B);
			C(734,629,p.T.C);
			C(757,634,p.T.D);
			C(960,639,p.T.D);
		}
		
		TestRootPanel _cRoot;
		void CheckHitTest(float x, float y, ClickPanel expect)
		{
			//root-level testing, used by uncapture input
			var hitResult = Fuse.Input.HitTestHelpers.HitTestNearest(_cRoot, float2(x,y));
			Assert.AreEqual(expect, hitResult.HitObject);
	
			//capture level routing
			//so longer as there is no overlap in the tests looking in each parent should produce the same result
			Visual start = expect;
			while (start != null)
			{
				var hitVisual = start.GetHitWindowPoint(float2(x,y));
				Assert.AreEqual(expect, hitVisual);
				start = start.Parent;
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
			_cRoot = TestRootPanel.CreateWithChild(p, int2(1000));
			_cRoot.CaptureDraw();
			TestBits(p, CheckColor);
		}
		
		void CheckColor(float x, float y, ClickPanel expect)
		{
			//assume Density=1 (note Y is inverted in GL buffer)
			var c = _cRoot.ReadDrawPixel( (int)x, (int)(1000 - y) );
			Assert.AreEqual(expect.Color, c);
		}
		
		[Test]
		/* 
			Viewport should be cacheable. This quick test tests for that. It's kept fairly light since the actual
			caching heuristic also plays a role here.
		*/
		public void Cache()
		{
			var p = new UX.ViewportCache();
			var r = TestRootPanel.CreateWithChild(p, int2(500));

			for (int i=0;i < 5; ++i)
				r.TestDraw();
			
			Assert.AreEqual(5,p.B.DrawCount);
			//Dependent on exact heuristic and can be changed, but certainly should be less than 5, probably 1 or 2
			Assert.AreEqual(1,p.A.DrawCount);
			Assert.AreEqual(1,p.C.DrawCount);
		}
		
		[Test]
		/*
			Viewports can flatten their children.
		*/
		public void IsFlat()
		{
			var p = new UX.ViewportFlat();
			var r = TestRootPanel.CreateWithChild(p);
			
			Assert.IsTrue(p.C.IsFlat);
			p.C.Mode = Fuse.Elements.ViewportMode.Disabled;
			Assert.IsFalse(p.C.IsFlat);
			p.R.DegreesX = 0;
			Assert.IsTrue(p.C.IsFlat);
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
