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
			root.CaptureDraw();

			float eps = 1.0f / 255;

			// Test a "random" pixel (center)
			Assert.AreEqual(float4(0), root.ReadDrawPixel(int2(50, 50)), eps);
		}

		[Test]
		public void SolidRectangleWithMarginDrawRectIsRendered()
		{
			var r = new UX.SolidRectangleWithMargin();
			var root = TestRootPanel.CreateWithChild(r, int2(100, 100));
			root.CaptureDraw();

			float eps = 1.0f / 255;

			// Test pixel outside of rect to ensure it's laid out how we expect
			Assert.AreEqual(float4(0), root.ReadDrawPixel(int2(9, 9)), eps);

			TestForDrawRect(root, new Recti(10, 10, 90, 90));
		}

		void TestForDrawRect(TestRootPanel root, Recti drawRectBounds)
		{
			float eps = 1.0f / 255;

			// TODO
			Assert.AreEqual(float4(0), root.ReadDrawPixel(int2(50, 50)), eps);
		}
	}
}
