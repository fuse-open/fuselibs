using Uno;
using Uno.Testing;
using Uno.Compiler;
using Fuse.Elements;
using Fuse;
using FuseTest;
using OpenGL;

namespace Fuse.Test
{

	public class CachingTest : TestBase
	{
		[Test]
		public void SubpixelCaching()
		{
			var p = new UX.SubpixelCaching();
			var root = TestRootPanel.CreateWithChild(p, int2(100, 200));
			using (var fb = root.CaptureDraw())
			{
				float eps = 1.0f / 255;

				// left border
				Assert.AreEqual(float4(0, 0, 0, 0), fb.ReadDrawPixel(int2(0, 50)), eps);
				Assert.AreEqual(float4(0, 0, 0, 0), fb.ReadDrawPixel(int2(0, 150)), eps);

				Assert.AreEqual(float4(0.375f, 0, 0, 0.375f), fb.ReadDrawPixel(int2(1, 50)), eps);
				Assert.AreEqual(float4(0, 0.375f, 0, 0.375f), fb.ReadDrawPixel(int2(1, 150)), eps);

				// right border
				Assert.AreEqual(float4(0.125f, 0, 0, 0.125f), fb.ReadDrawPixel(int2(99, 50)), eps);
				Assert.AreEqual(float4(0, 0.125f, 0, 0.125f), fb.ReadDrawPixel(int2(99, 150)), eps);

				Assert.AreEqual(float4(0.5f, 0, 0, 0.5f), fb.ReadDrawPixel(int2(98, 50)), eps);
				Assert.AreEqual(float4(0, 0.5f, 0, 0.5f), fb.ReadDrawPixel(int2(98, 150)), eps);

				// top border
				Assert.AreEqual(float4(0.125f, 0, 0, 0.125f), fb.ReadDrawPixel(int2(50,  99)), eps);
				Assert.AreEqual(float4(0, 0.125f, 0, 0.125f), fb.ReadDrawPixel(int2(50, 199)), eps);

				Assert.AreEqual(float4(0.5f, 0, 0, 0.5f), fb.ReadDrawPixel(int2(50, 98)), eps);
				Assert.AreEqual(float4(0, 0.5f, 0, 0.5f), fb.ReadDrawPixel(int2(50, 198)), eps);

				// bottom border
				Assert.AreEqual(float4(0, 0, 0, 0), fb.ReadDrawPixel(int2(50, 0)), eps);
				Assert.AreEqual(float4(0, 0, 0, 0), fb.ReadDrawPixel(int2(50, 100)), eps);

				Assert.AreEqual(float4(0.375f, 0, 0, 0.375f), fb.ReadDrawPixel(int2(50, 1)), eps);
				Assert.AreEqual(float4(0, 0.375f, 0, 0.375f), fb.ReadDrawPixel(int2(50, 101)), eps);
			}
		}

		[Test]
		public void BorderIssue()
		{
			var p = new UX.Caching.BorderIssue();
			var root = TestRootPanel.CreateWithChild(p, int2(32, 32));
			using (var fb = root.CaptureDraw())
			{
				for (int y = -15; y < 16; ++y)
				{
					for (int x = -15; x < 16; ++x)
					{
						int manhattanDistance = Math.Max(Math.Abs(x), Math.Abs(y));

						// check red rectangle
						if (manhattanDistance < 4)
							Assert.AreEqual(float4(1.0f, 0, 0, 1.0f), fb.ReadDrawPixel(int2(16 + x, 16 + y)));

						// check outside red and green rectangle
						if (manhattanDistance > 6)
							Assert.AreEqual(float4(0.0f, 0.0f, 0.0f, 0.0f), fb.ReadDrawPixel(int2(16 + x, 16 + y)));
					}
				}
			}
		}
	}
}
