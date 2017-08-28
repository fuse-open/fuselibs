using Uno;
using Uno.Testing;

using FuseTest;
using Fuse.Controls;
using Fuse.Resources;

namespace Fuse.Controls.Primitives.Test
{
	public class ShadowTest : TestBase
	{
		[Test]
		public void Underlay()
		{
			var p = new UX.Shadow.Panel();
			p._shadow.Size = 10;
			using (var root = TestRootPanel.CreateWithChild(p, int2(300, 300)))
			using (var fb = root.CaptureDraw())
			{
				// check that the element is on top
				fb.AssertPixel(float4(1, 0, 0, 1), int2( 50, 150)); // left border
				fb.AssertPixel(float4(1, 0, 0, 1), int2(249, 150)); // right border
				fb.AssertPixel(float4(1, 0, 0, 1), int2(150, 249)); // bottom border
				fb.AssertPixel(float4(1, 0, 0, 1), int2(150,  50)); // top border
			}
		}

		[Test]
		public void Padding()
		{
			var p = new UX.Shadow.Panel();
			p._panel.Padding = float4(10);
			p._shadow.Size = 0;
			p._shadow.Angle = -45;
			p._shadow.Distance = Vector.Length(float2(10, 10));
			using (var root = TestRootPanel.CreateWithChild(p, int2(300, 300)))
			using (var fb = root.CaptureDraw())
			{
				fb.AssertPixel(float4(1, 0, 0, 1),        int2(50, 50));
				fb.AssertPixel(Fuse.Drawing.Colors.Green, int2(41, 41), 0.01f);
				fb.AssertPixel(float4(0, 0, 0, 0),        int2(39, 39));
			}
		}

		[Test]
		public void Falloff()
		{
			var p = new UX.Shadow.Panel();
			p._shadow.Size = 10;
			using (var root = TestRootPanel.CreateWithChild(p, int2(300, 300)))
			using (var fb = root.CaptureDraw())
			{
				// sample a few values from the middle of the shadow. Reference values are taken from ShadowMode.PerPixel.
				fb.AssertPixel(float4(0, 0, 0, 0), int2(30, 150)); // left border
				fb.AssertPixel(float4(0, 0.0156863f, 0, 0.0274510f), int2(40, 150), 0.02f); // left border
				fb.AssertPixel(float4(0, 0.2274510f, 0, 0.4549020f), int2(49, 150), 0.01f); // left border
				fb.AssertPixel(float4(0, 0.2274510f, 0, 0.4549020f),  int2(250, 150), 0.01f); // right border
				fb.AssertPixel(float4(0, 0.0156863f, 0, 0.0274510f), int2(259, 150), 0.02f); // right border
				fb.AssertPixel(float4(0, 0, 0, 0), int2(269, 150)); // right border
			}
		}

		[Test]
		public void CornerRadius()
		{
			var p = new UX.Shadow.Rectangle();
			p._shadow.Size = 0;
			p._shadow.Angle = -45;
			p._shadow.Distance = Vector.Length(float2(10, 10));

			using (var root = TestRootPanel.CreateWithChild(p, int2(300, 300)))
			{
				float[] cornerRadiuses = new float[] {10, 20, 0, 5};
				for (int i = 0; i < cornerRadiuses.Length; ++i)
				{
					float radius = cornerRadiuses[i];
					p._rectangle.CornerRadius = float4(radius);
					using (var fb = root.CaptureDraw())
					{
						// bottom-left corner
						var cornerEdge = (1.0f - 1.0f / Math.Sqrt(2.0f)) * radius;
						var innerPixel = 40 + (int)Math.Floor(cornerEdge - 1.5f);
						var outerPixel = 40 + (int)Math.Ceil(cornerEdge + 1.5f);
						fb.AssertPixel(float4(0, 0, 0, 0),        int2(innerPixel));
						fb.AssertPixel(Fuse.Drawing.Colors.Green, int2(outerPixel), 0.01f);
					}
				}
			}
		}

		[Test]
		public void ColorPanel()
		{
			var p = new UX.Shadow.Panel();
			p._panel.Color = float4(1, 0, 0, 0.5f);
			p._shadow.Size = 0;
			p._shadow.Angle = -45;
			p._shadow.Distance = Vector.Length(float2(10, 10));

			using (var root = TestRootPanel.CreateWithChild(p, int2(300, 300)))
			using (var fb = root.CaptureDraw())
			{
				fb.AssertPixel(float4(0.5f, 0.25f, 0, 1), int2(50), 0.01f);
				fb.AssertPixel(float4(0, 0.5f, 0, 1),     int2(41), 0.01f);
			}
		}

		[Test]
		public void ColorRectangle()
		{
			var p = new UX.Shadow.Rectangle();
			p._rectangle.Color = float4(1, 0, 0, 0.5f);
			p._shadow.Size = 0;
			p._shadow.Angle = -45;
			p._shadow.Distance = Vector.Length(float2(10, 10));

			using (var root = TestRootPanel.CreateWithChild(p, int2(300, 300)))
			using (var fb = root.CaptureDraw())
			{
				fb.AssertPixel(float4(0.5f, 0.25f, 0, 1), int2(50), 0.01f);
				fb.AssertPixel(float4(0, 0.5f, 0, 1),     int2(41), 0.01f);
			}
		}

		[Test]
		public void InvisiblePanel()
		{
			var p = new UX.Shadow.Panel();
			p._panel.Color = float4(0, 0, 0, 0);

			using (var root = TestRootPanel.CreateWithChild(p, int2(300, 300)))
			using (var fb = root.CaptureDraw())
			{
				fb.AssertPixel(float4(0, 0.5f, 0, 1), int2(100), 0.01f);
			}
		}

		[Test]
		public void InvisibleRectangle()
		{
			var p = new UX.Shadow.Rectangle();
			p._rectangle.Color = float4(0, 0, 0, 0);

			using (var root = TestRootPanel.CreateWithChild(p, int2(300, 300)))
			using (var fb = root.CaptureDraw())
			{
				fb.AssertPixel(float4(0, 0.5f, 0, 1), int2(100), 0.01f);
			}
		}
	}
}
