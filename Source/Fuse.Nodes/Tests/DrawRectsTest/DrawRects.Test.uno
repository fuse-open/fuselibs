using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.Math;
using Uno.Testing;
using Uno.Threading;
using Fuse;
using Fuse.Controls;
using FuseTest;

namespace DrawRectsTest
{
	using DotNetNative;

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
				// Test pixel outside of element to ensure it's laid out how we expect
				fb.AssertPixel(float4(0), int2(5, 5));

				TestForDrawRects(fb, new Recti(10, 10, 90, 90), 1, float4(1));
			}
		}

		[Test]
		public void SolidCachedRectangleWithMarginDrawRectIsRendered()
		{
			var r = new global::UX.SolidCachedRectangleWithMargin();
			var root = TestRootPanel.CreateWithChild(r, int2(100, 100));

			using (var fb = root.CaptureDraw())
			{
				// Test pixel outside of element to ensure it's laid out how we expect
				fb.AssertPixel(float4(0), int2(5, 5));

				TestForDrawRects(fb, new Recti(10, 10, 90, 90), 1, float4(1));
			}
		}

		[Test]
		public void PanelWithBackgroundAndMarginDrawRectIsRendered()
		{
			var c = new global::UX.PanelWithBackgroundAndMargin();
			var root = TestRootPanel.CreateWithChild(c, int2(100, 100));

			using (var fb = root.CaptureDraw())
			{
				// Test pixel outside of element to ensure it's laid out how we expect
				fb.AssertPixel(float4(0), int2(5, 5));

				TestForDrawRects(fb, new Recti(10, 10, 90, 90), 1, float4(0, 1, 0, 1));
			}
		}

		[Test]
		public void CircleWithBackgroundAndMarginDrawRectIsRendered()
		{
			var c = new global::UX.CircleWithBackgroundAndMargin();
			var root = TestRootPanel.CreateWithChild(c, int2(200, 100));

			using (var fb = root.CaptureDraw())
			{
				// Test pixel outside of element to ensure it's laid out how we expect
				fb.AssertPixel(float4(0), int2(5, 5));

				TestForDrawRects(fb, new Recti(60, 10, 140, 90), 1, float4(0), float4(1));
			}
		}

		[Test]
		public void FrozenPanelWithBackgroundAndMarginDrawRectIsRendered()
		{
			var c = new global::UX.FrozenPanelWithBackgroundAndMargin();
			var root = TestRootPanel.CreateWithChild(c, int2(100, 100));

			using (var fb = root.CaptureDraw())
			{
				// Test pixel outside of element to ensure it's laid out how we expect
				fb.AssertPixel(float4(0), int2(5, 5));

				TestForDrawRects(fb, new Recti(10, 10, 90, 90), 1, float4(0, 0, 1, 1));
			}
		}

		[Test]
		public void SolidRectangleWithBlurAndMarginDrawRectIsRendered()
		{
			var r = new global::UX.SolidRectangleWithBlurAndMargin();
			var root = TestRootPanel.CreateWithChild(r, int2(100, 100));

			using (var fb = root.CaptureDraw())
			{
				// Test pixel outside of element to ensure it's laid out how we expect
				fb.AssertPixel(float4(0), int2(5, 5));

				TestForDrawRects(fb, new Recti(10, 10, 90, 90), 1, float4(1));
			}
		}

		[Test]
		public void SolidRectangleWithDesaturateAndMarginDrawRectIsRendered()
		{
			var r = new global::UX.SolidRectangleWithDesaturateAndMargin();
			var root = TestRootPanel.CreateWithChild(r, int2(100, 100));

			using (var fb = root.CaptureDraw())
			{
				// Test pixel outside of element to ensure it's laid out how we expect
				fb.AssertPixel(float4(0), int2(5, 5));

				TestForDrawRects(fb, new Recti(10, 10, 90, 90), 1, float4(1));
			}
		}

		[Test]
		public void SolidRectangleWithDropShadowAndMarginDrawRectIsRendered()
		{
			var r = new global::UX.SolidRectangleWithDropShadowAndMargin();
			var root = TestRootPanel.CreateWithChild(r, int2(100, 100));

			using (var fb = root.CaptureDraw())
			{
				// Test pixel outside of element to ensure it's laid out how we expect
				fb.AssertPixel(float4(0), int2(5, 5));

				TestForDrawRects(fb, new Recti(10, 10, 90, 90), 2, float4(1));
			}
		}

		[Test]
		public void SolidRectangleWithDuotoneAndMarginDrawRectIsRendered()
		{
			var r = new global::UX.SolidRectangleWithDuotoneAndMargin();
			var root = TestRootPanel.CreateWithChild(r, int2(100, 100));

			using (var fb = root.CaptureDraw())
			{
				// Test pixel outside of element to ensure it's laid out how we expect
				fb.AssertPixel(float4(0), int2(5, 5));

				TestForDrawRects(fb, new Recti(10, 10, 90, 90), 1, float4(1));
			}
		}

		[Test]
		public void SolidRectangleWithHalftoneAndMarginDrawRectIsRendered()
		{
			var r = new global::UX.SolidRectangleWithHalftoneAndMargin();
			var root = TestRootPanel.CreateWithChild(r, int2(100, 100));

			using (var fb = root.CaptureDraw())
			{
				// Test pixel outside of element to ensure it's laid out how we expect
				fb.AssertPixel(float4(0), int2(5, 5));

				TestForDrawRects(fb, new Recti(10, 10, 90, 90), 1, float4(1));
			}
		}

		[Test]
		public void SolidRectangleWithMaskAndMarginDrawRectIsRendered()
		{
			var r = new global::UX.SolidRectangleWithMaskAndMargin();
			var root = TestRootPanel.CreateWithChild(r, int2(100, 100));

			using (var fb = root.CaptureDraw())
			{
				// Test pixel outside of element to ensure it's laid out how we expect
				fb.AssertPixel(float4(0), int2(5, 5));

				TestForDrawRects(fb, new Recti(10, 10, 90, 90), 1, float4(1));
			}
		}

		[Test]
		public void ViewportWithRectangleDrawRectIsRendered()
		{
			var r = new global::UX.ViewportWithRectangle();
			var root = TestRootPanel.CreateWithChild(r, int2(100, 100));

			using (var fb = root.CaptureDraw())
			{
				// Test pixel outside of element to ensure it's laid out how we expect
				fb.AssertPixel(float4(0), int2(5, 5));

				TestForDrawRects(fb, new Recti(10, 10, 90, 90), 1, float4(1));
			}
		}

		[Test]
		public void ImageWithMarginDrawRectIsRendered()
		{
			var c = new global::UX.ImageWithMargin();
			var root = TestRootPanel.CreateWithChild(c, int2(200, 100));

			using (var fb = root.CaptureDraw())
			{
				// Test pixel outside of element to ensure it's laid out how we expect
				fb.AssertPixel(float4(0), int2(5, 5));

				TestForDrawRects(fb, new Recti(60, 10, 140, 90), 1, float4(1));
			}
		}

		extern(DOTNET) static class MessagePumper
		{
			public static void PumpMessages()
			{
				DotNetNative.Application.DoEvents();
			}
		}

		extern(!DOTNET) static class MessagePumper
		{
			public static void PumpMessages()
			{
				// Do nothing
			}
		}

		[Test]
		public void VideoWithMarginDrawRectIsRendered()
		{
			var c = new global::UX.VideoWithMargin();
			var root = TestRootPanel.CreateWithChild(c, int2(200, 100));

			// Wait until the video is playing before grabbing pixels
			while (!c.IsPlaying)
			{
				root.StepFrame();
				root.TestDraw();
				MessagePumper.PumpMessages();
				Thread.Sleep(16);
			}

			// Step some more frames so the video will start playing
			for (int i = 0; i < 10; i++)
			{
				root.StepFrame();
				root.TestDraw();
				MessagePumper.PumpMessages();
				Thread.Sleep(16);
			}

			using (var fb = root.CaptureDraw())
			{
				// Test pixel outside of element to ensure it's laid out how we expect
				fb.AssertPixel(float4(0), int2(5, 5));

				TestForDrawRects(fb, new Recti(60, 10, 140, 90), 1, float4(float3(0.92f), 1));
			}
		}

		void TestForDrawRects(TestFramebuffer fb, Recti drawRectBounds, int numRects, float4 drawnColor)
		{
			TestForDrawRects(fb, drawRectBounds, numRects, drawnColor, drawnColor);
		}

		void TestForDrawRects(TestFramebuffer fb, Recti drawRectBounds, int numRects, float4 drawnCornerColor, float4 drawnCenterColor)
		{
			// Slightly larger epsilon than normal since we're testing for a blended rect with some margin etc
			float eps = 5.0f / 255.0f;

			// Darken incoming color to simulate darkened rect drawn before the draw rects
			float4 darkeningRectColor = float4(0, 0, 0, 0.5f);
			float4 darkenedCornerColor = float4(darkeningRectColor.XYZ * darkeningRectColor.W + drawnCornerColor.XYZ * (1.0f - darkeningRectColor.W), drawnCornerColor.W);
			float4 darkenedCenterColor = float4(darkeningRectColor.XYZ * darkeningRectColor.W + drawnCenterColor.XYZ * (1.0f - darkeningRectColor.W), drawnCenterColor.W);

			// Calculate the colors of the rendered draw rect
			var leftTopColor = float4(0, 0, 0, 1);
			var rightTopColor = float4(1, 0, 0, 1);
			var leftBottomColor = float4(0, 1, 0, 1);
			var rightBottomColor = float4(1, 1, 0, 1);
			var middleColor = (leftTopColor + rightTopColor + leftBottomColor + rightBottomColor) / 4.0f;
			float alpha = 0.2f;

			// Test for the rendered draw rect at a few expected points in the drawn rect
			//  We make sure to apply a little margin around the edges to be sure we test inside the rect
			int margin = 1;
			fb.AssertPixel(Math.Saturate(darkenedCornerColor + leftTopColor * alpha * (float)numRects), drawRectBounds.LeftTop + int2(margin, margin), eps);
			fb.AssertPixel(Math.Saturate(darkenedCornerColor + rightTopColor * alpha * (float)numRects), drawRectBounds.RightTop + int2(-margin, margin), eps);
			fb.AssertPixel(Math.Saturate(darkenedCornerColor + leftBottomColor * alpha * (float)numRects), drawRectBounds.LeftBottom + int2(margin, -margin), eps);
			fb.AssertPixel(Math.Saturate(darkenedCornerColor + rightBottomColor * alpha * (float)numRects), drawRectBounds.RightBottom + int2(-margin, -margin), eps);
			fb.AssertPixel(Math.Saturate(darkenedCenterColor + middleColor * alpha * (float)numRects), drawRectBounds.Center, eps);
		}
	}

	namespace DotNetNative
	{
		[DotNetType("System.Windows.Forms.Application")]
		extern(DOTNET) public class Application
		{
			public extern static void DoEvents();
		}
	}
}
