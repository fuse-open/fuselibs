using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.Math;
using Uno.Testing;
using Uno.Threading;
using Fuse;
using Fuse.Controls;
using Fuse.Nodes;
using FuseTest;

namespace DrawRectsTest
{
	using DotNetNative;

	public class DrawRectsTest : TestBase
	{
		static float4 DarkeningRectColor = float4(0, 0, 0, 0.5f);

		[Test]
		public void EmptyPanelIsBlack()
		{
			try
			{
				DrawRectVisualizer.IsCaptureEnabled = true;

				var p = new Panel();
				using (var root = TestRootPanel.CreateWithChild(p, int2(100, 100)))
				using (var fb = root.CaptureDraw())
				{
					// Test a "random" pixel (center)
					fb.AssertPixel(DarkeningRectColor, int2(50, 50), 1.5f / 255);
				}
			}
			finally
			{
				DrawRectVisualizer.IsCaptureEnabled = false;
			}
		}

		[Test]
		public void SolidRectangleWithMarginDrawRectIsRendered()
		{
			try
			{
				DrawRectVisualizer.IsCaptureEnabled = true;

				var r = new global::UX.SolidRectangleWithMargin();
				using (var root = TestRootPanel.CreateWithChild(r, int2(100, 100)))
				using (var fb = root.CaptureDraw())
				{
					// Test pixel outside of element to ensure it's laid out how we expect
					fb.AssertPixel(DarkeningRectColor, int2(5, 5), 1.5f / 255);

					TestForDrawRects(fb, new Recti(10, 10, 90, 90), 1, float4(1));
				}
			}
			finally
			{
				DrawRectVisualizer.IsCaptureEnabled = false;
			}
		}

		[Test]
		public void SolidCachedRectangleWithMarginDrawRectIsRendered()
		{
			try
			{
				DrawRectVisualizer.IsCaptureEnabled = true;

				var r = new global::UX.SolidCachedRectangleWithMargin();
				using (var root = TestRootPanel.CreateWithChild(r, int2(100, 100)))
				using (var fb = root.CaptureDraw())
				{
					// Test pixel outside of element to ensure it's laid out how we expect
					fb.AssertPixel(DarkeningRectColor, int2(5, 5), 1.5f / 255);

					TestForDrawRects(fb, new Recti(10, 10, 90, 90), 1, float4(1));
				}
			}
			finally
			{
				DrawRectVisualizer.IsCaptureEnabled = false;
			}
		}

		[Test]
		public void PanelWithBackgroundAndMarginDrawRectIsRendered()
		{
			try
			{
				DrawRectVisualizer.IsCaptureEnabled = true;

				var c = new global::UX.PanelWithBackgroundAndMargin();
				using (var root = TestRootPanel.CreateWithChild(c, int2(100, 100)))
				using (var fb = root.CaptureDraw())
				{
					// Test pixel outside of element to ensure it's laid out how we expect
					fb.AssertPixel(DarkeningRectColor, int2(5, 5), 1.5f / 255);

					TestForDrawRects(fb, new Recti(10, 10, 90, 90), 1, float4(0, 1, 0, 1));
				}
			}
			finally
			{
				DrawRectVisualizer.IsCaptureEnabled = false;
			}
		}

		[Test]
		public void CircleWithBackgroundAndMarginDrawRectIsRendered()
		{
			try
			{
				DrawRectVisualizer.IsCaptureEnabled = true;

				var c = new global::UX.CircleWithBackgroundAndMargin();
				using (var root = TestRootPanel.CreateWithChild(c, int2(200, 100)))
				using (var fb = root.CaptureDraw())
				{
					// Test pixel outside of element to ensure it's laid out how we expect
					fb.AssertPixel(DarkeningRectColor, int2(5, 5), 1.5f / 255);

					TestForDrawRects(fb, new Recti(60, 10, 140, 90), 1, float4(0), float4(1));
				}
			}
			finally
			{
				DrawRectVisualizer.IsCaptureEnabled = false;
			}
		}

		[Test]
		public void FrozenPanelWithBackgroundAndMarginDrawRectIsRendered()
		{
			try
			{
				DrawRectVisualizer.IsCaptureEnabled = true;

				var c = new global::UX.FrozenPanelWithBackgroundAndMargin();
				using (var root = TestRootPanel.CreateWithChild(c, int2(100, 100)))
				using (var fb = root.CaptureDraw())
				{
					// Test pixel outside of element to ensure it's laid out how we expect
					fb.AssertPixel(DarkeningRectColor, int2(5, 5), 1.5f / 255);

					TestForDrawRects(fb, new Recti(10, 10, 90, 90), 1, float4(0, 0, 1, 1));
				}
			}
			finally
			{
				DrawRectVisualizer.IsCaptureEnabled = false;
			}
		}

		[Test]
		public void SolidRectangleWithBlurAndMarginDrawRectIsRendered()
		{
			try
			{
				DrawRectVisualizer.IsCaptureEnabled = true;

				var r = new global::UX.SolidRectangleWithBlurAndMargin();
				using (var root = TestRootPanel.CreateWithChild(r, int2(100, 100)))
				using (var fb = root.CaptureDraw())
				{
					// Test pixel outside of element to ensure it's laid out how we expect
					fb.AssertPixel(DarkeningRectColor, int2(5, 5), 1.5f / 255);

					TestForDrawRects(fb, new Recti(10, 10, 90, 90), 1, float4(1));
				}
			}
			finally
			{
				DrawRectVisualizer.IsCaptureEnabled = false;
			}
		}

		[Test]
		public void SolidRectangleWithDesaturateAndMarginDrawRectIsRendered()
		{
			try
			{
				DrawRectVisualizer.IsCaptureEnabled = true;

				var r = new global::UX.SolidRectangleWithDesaturateAndMargin();
				using (var root = TestRootPanel.CreateWithChild(r, int2(100, 100)))
				using (var fb = root.CaptureDraw())
				{
					// Test pixel outside of element to ensure it's laid out how we expect
					fb.AssertPixel(DarkeningRectColor, int2(5, 5), 1.5f / 255);

					TestForDrawRects(fb, new Recti(10, 10, 90, 90), 1, float4(1));
				}
			}
			finally
			{
				DrawRectVisualizer.IsCaptureEnabled = false;
			}
		}

		[Test]
		public void SolidRectangleWithDropShadowAndMarginDrawRectIsRendered()
		{
			try
			{
				DrawRectVisualizer.IsCaptureEnabled = true;

				var r = new global::UX.SolidRectangleWithDropShadowAndMargin();
				using (var root = TestRootPanel.CreateWithChild(r, int2(100, 100)))
				using (var fb = root.CaptureDraw())
				{
					// Test pixel outside of element to ensure it's laid out how we expect
					fb.AssertPixel(DarkeningRectColor, int2(5, 5), 1.5f / 255);

					TestForDrawRects(fb, new Recti(10, 10, 90, 90), 2, float4(1));
				}
			}
			finally
			{
				DrawRectVisualizer.IsCaptureEnabled = false;
			}
		}

		[Test]
		public void SolidRectangleWithDuotoneAndMarginDrawRectIsRendered()
		{
			try
			{
				DrawRectVisualizer.IsCaptureEnabled = true;

				var r = new global::UX.SolidRectangleWithDuotoneAndMargin();
				using (var root = TestRootPanel.CreateWithChild(r, int2(100, 100)))
				using (var fb = root.CaptureDraw())
				{
					// Test pixel outside of element to ensure it's laid out how we expect
					fb.AssertPixel(DarkeningRectColor, int2(5, 5), 1.5f / 255);

					TestForDrawRects(fb, new Recti(10, 10, 90, 90), 1, float4(1));
				}
			}
			finally
			{
				DrawRectVisualizer.IsCaptureEnabled = false;
			}
		}

		[Test]
		public void SolidRectangleWithHalftoneAndMarginDrawRectIsRendered()
		{
			try
			{
				DrawRectVisualizer.IsCaptureEnabled = true;

				var r = new global::UX.SolidRectangleWithHalftoneAndMargin();
				using (var root = TestRootPanel.CreateWithChild(r, int2(100, 100)))
				using (var fb = root.CaptureDraw())
				{
					// Test pixel outside of element to ensure it's laid out how we expect
					fb.AssertPixel(DarkeningRectColor, int2(5, 5), 1.5f / 255);

					TestForDrawRects(fb, new Recti(10, 10, 90, 90), 1, float4(1));
				}
			}
			finally
			{
				DrawRectVisualizer.IsCaptureEnabled = false;
			}
		}

		[Test]
		public void SolidRectangleWithMaskAndMarginDrawRectIsRendered()
		{
			try
			{
				DrawRectVisualizer.IsCaptureEnabled = true;

				var r = new global::UX.SolidRectangleWithMaskAndMargin();
				using (var root = TestRootPanel.CreateWithChild(r, int2(100, 100)))
				using (var fb = root.CaptureDraw())
				{
					// Test pixel outside of element to ensure it's laid out how we expect
					fb.AssertPixel(DarkeningRectColor, int2(5, 5), 1.5f / 255);

					TestForDrawRects(fb, new Recti(10, 10, 90, 90), 1, float4(1));
				}
			}
			finally
			{
				DrawRectVisualizer.IsCaptureEnabled = false;
			}
		}

		[Test]
		public void ViewportWithRectangleDrawRectIsRendered()
		{
			try
			{
				DrawRectVisualizer.IsCaptureEnabled = true;

				var r = new global::UX.ViewportWithRectangle();
				using (var root = TestRootPanel.CreateWithChild(r, int2(100, 100)))
				using (var fb = root.CaptureDraw())
				{
					// Test pixel outside of element to ensure it's laid out how we expect
					fb.AssertPixel(DarkeningRectColor, int2(5, 5), 1.5f / 255);

					TestForDrawRects(fb, new Recti(10, 10, 90, 90), 1, float4(1));
				}
			}
			finally
			{
				DrawRectVisualizer.IsCaptureEnabled = false;
			}
		}

		[Test]
		public void ImageWithMarginDrawRectIsRendered()
		{
			try
			{
				DrawRectVisualizer.IsCaptureEnabled = true;

				var c = new global::UX.ImageWithMargin();
				using (var root = TestRootPanel.CreateWithChild(c, int2(200, 100)))
				using (var fb = root.CaptureDraw())
				{
					// Test pixel outside of element to ensure it's laid out how we expect
					fb.AssertPixel(DarkeningRectColor, int2(5, 5), 1.5f / 255);

					TestForDrawRects(fb, new Recti(60, 10, 140, 90), 1, float4(1));
				}
			}
			finally
			{
				DrawRectVisualizer.IsCaptureEnabled = false;
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
		[Ignore("https://github.com/fuse-open/fuselibs/issues/297")]
		public void VideoWithMarginDrawRectIsRendered()
		{
			try
			{
				DrawRectVisualizer.IsCaptureEnabled = true;

				var c = new global::UX.VideoWithMargin();
				using (var root = TestRootPanel.CreateWithChild(c, int2(200, 100)))
				{
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
						fb.AssertPixel(DarkeningRectColor, int2(5, 5), 1.5f / 255);

						TestForDrawRects(fb, new Recti(60, 10, 140, 90), 1, float4(float3(0.92f), 1));
					}
				}
			}
			finally
			{
				DrawRectVisualizer.IsCaptureEnabled = false;
			}
		}

		[Test]
		public void Scale9ImageWithMarginDrawRectIsRendered()
		{
			try
			{
				DrawRectVisualizer.IsCaptureEnabled = true;

				var c = new global::UX.Scale9ImageWithMargin();
				using (var root = TestRootPanel.CreateWithChild(c, int2(200, 100)))
				using (var fb = root.CaptureDraw())
				{
					// Test pixel outside of element to ensure it's laid out how we expect
					fb.AssertPixel(DarkeningRectColor, int2(5, 5), 1.5f / 255);

					TestForDrawRects(fb, new Recti(10, 10, 190, 90), 1, float4(1));
				}
			}
			finally
			{
				DrawRectVisualizer.IsCaptureEnabled = false;
			}
		}

		[Test]
		[Ignore("https://github.com/fuse-open/fuselibs/issues/297")]
		public void Scale9VideoWithMarginDrawRectIsRendered()
		{
			try
			{
				DrawRectVisualizer.IsCaptureEnabled = true;

				var c = new global::UX.Scale9VideoWithMargin();
				using (var root = TestRootPanel.CreateWithChild(c, int2(200, 100)))
				{
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
						fb.AssertPixel(DarkeningRectColor, int2(5, 5), 1.5f / 255);

						TestForDrawRects(fb, new Recti(10, 10, 190, 90), 1, float4(float3(0.92f), 1));
					}
				}
			}
			finally
			{
				DrawRectVisualizer.IsCaptureEnabled = false;
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
			float4 darkenedCornerColor = float4(DarkeningRectColor.XYZ * DarkeningRectColor.W + drawnCornerColor.XYZ * (1.0f - DarkeningRectColor.W), DarkeningRectColor.W + drawnCornerColor.W);
			float4 darkenedCenterColor = float4(DarkeningRectColor.XYZ * DarkeningRectColor.W + drawnCenterColor.XYZ * (1.0f - DarkeningRectColor.W), DarkeningRectColor.W + drawnCenterColor.W);

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
