using Uno;
using Uno.Testing;
using Fuse;
using Fuse.Controls;
using FuseTest;

namespace DrawRectsTest
{
	public class DrawRectsTest : TestBase
	{
		[Test]
		public void EmptyPanelIsBlack()
		{
			var p = new Panel();
			var root = TestRootPanel.CreateWithChild(p, int2(100, 100));

			using (var fb = root.CaptureDraw())
			{
				// Test a "random" pixel (center)
				fb.AssertPixel(float4(0), int2(50, 50));
			}
		}

		[Test]
		public void SolidRectangleWithMarginDrawRectIsRendered()
		{
			var r = new global::UX.SolidRectangleWithMargin();
			var root = TestRootPanel.CreateWithChild(r, int2(100, 100));

			using (var fb = root.CaptureDraw())
			{
				// Test pixel outside of rect to ensure it's laid out how we expect
				fb.AssertPixel(float4(0), int2(9, 9));

				TestForDrawRect(fb, new Recti(10, 10, 90, 90));
			}
		}

		void TestForDrawRect(TestFramebuffer fb, Recti drawRectBounds)
		{
			// TODO
			fb.AssertPixel(float4(0), int2(50, 50));
		}
	}
}
