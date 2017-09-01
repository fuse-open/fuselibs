using Uno;
using Uno.Testing;

using Fuse.Triggers;

using FuseTest;

namespace Fuse.Gestures.Test
{
	/* Tests that cover priority resolution and interactions between gestures. These don't really belong on any of the individual gestures. */
	public class GestureTest : TestBase
	{
		[Test]
		public void Layer()
		{	
			var p = new UX.Gesture.Layer();
			using (var root = TestRootPanel.CreateWithChild(p, int2(1000)))
			{
				Assert.AreEqual(p.pageB, p.edgeMain.Active);
				Assert.AreEqual(float2(0,0), p.rangeH.ActualPosition);
				Assert.AreEqual(float2(1000,20), p.rangeH.ActualSize);

				//swipe in the right Edge panel
				root.PointerSwipe(float2(990,50), float2(790,50), 100);
				root.StepFrame(5);//stabilize
				Assert.AreEqual(p.edgeRight, p.edge.Active);
				Assert.AreEqual(p.pageB, p.edgeMain.Active);

				//swipe away the right EgeNavigator panel
				root.PointerSwipe(float2(810,50), float2(950,50), 100);
				root.StepFrame(5);//stabilize
				Assert.AreEqual(p.edgeMain, p.edge.Active);
				Assert.AreEqual(p.pageB, p.edgeMain.Active);

				//swipe the RangeControl
				root.PointerSwipe(float2(600,10), float2(400,10), 100);
				Assert.AreEqual(40, p.rangeH.Value);

				//swipe left edge of EdgeNavigator
				root.PointerSwipe(float2(10,50), float2(190,50), 100);
				root.StepFrame(5);//stabilize
				Assert.AreEqual(p.edgeLeft, p.edge.Active);

				//swipe central gesture down
				root.PointerSwipe(float2(500,75), float2(500,175), 100);
				Assert.AreEqual(1,p.downCount.PerformedCount);
				Assert.AreEqual(0,p.scroll.ScrollPosition.Y);

				//swipe the scrollView
				root.PointerSwipe(float2(500,500), float2(500,400), 50);
				root.StepFrame(5);
				var y = p.scroll.ScrollPosition.Y;
				Assert.IsTrue(y > 50);

				//swipe higher up gesture from bottom
				root.PointerSwipe(float2(500,999), float2(500,900), 100);
				Assert.AreEqual(y, p.scroll.ScrollPosition.Y);
				Assert.AreEqual(1,p.upCount.PerformedCount);

				//swipe the page
				root.PointerSwipe(float2(600,500), float2(400,500), 500);
				root.StepFrame(5);
				Assert.AreEqual(40, p.rangeH.Value);
				Assert.AreEqual(p.pageC, p.edgeMain.Active);
				


			}
		}
	}
}
