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
			using (var root = TestRootPanel.CreateWithChild(p, int2(100, 200)))
			using (var fb = root.CaptureDraw())
			{
				float eps = 1.0f / 255;

				// left border
				fb.AssertPixel(float4(0, 0, 0, 0), int2(0, 50), eps);
				fb.AssertPixel(float4(0, 0, 0, 0), int2(0, 150), eps);

				fb.AssertPixel(float4(0.375f, 0, 0, 0.375f), int2(1, 50), eps);
				fb.AssertPixel(float4(0, 0.375f, 0, 0.375f), int2(1, 150), eps);

				// right border
				fb.AssertPixel(float4(0.125f, 0, 0, 0.125f), int2(99, 50), eps);
				fb.AssertPixel(float4(0, 0.125f, 0, 0.125f), int2(99, 150), eps);

				fb.AssertPixel(float4(0.5f, 0, 0, 0.5f), int2(98, 50), eps);
				fb.AssertPixel(float4(0, 0.5f, 0, 0.5f), int2(98, 150), eps);

				// top border
				fb.AssertPixel(float4(0.125f, 0, 0, 0.125f), int2(50,  99), eps);
				fb.AssertPixel(float4(0, 0.125f, 0, 0.125f), int2(50, 199), eps);

				fb.AssertPixel(float4(0.5f, 0, 0, 0.5f), int2(50, 98), eps);
				fb.AssertPixel(float4(0, 0.5f, 0, 0.5f), int2(50, 198), eps);

				// bottom border
				fb.AssertPixel(float4(0, 0, 0, 0), int2(50, 0), eps);
				fb.AssertPixel(float4(0, 0, 0, 0), int2(50, 100), eps);

				fb.AssertPixel(float4(0.375f, 0, 0, 0.375f), int2(50, 1), eps);
				fb.AssertPixel(float4(0, 0.375f, 0, 0.375f), int2(50, 101), eps);
			}
		}

		[Test]
		public void BorderIssue()
		{
			var p = new UX.Caching.BorderIssue();
			using (var root = TestRootPanel.CreateWithChild(p, int2(32, 32)))
			using (var fb = root.CaptureDraw())
			{
				for (int y = -15; y < 16; ++y)
				{
					for (int x = -15; x < 16; ++x)
					{
						int manhattanDistance = Math.Max(Math.Abs(x), Math.Abs(y));

						// check red rectangle
						if (manhattanDistance < 4)
							fb.AssertPixel(float4(1, 0, 0, 1), int2(16 + x, 16 + y));

						// check outside red and green rectangle
						if (manhattanDistance > 6)
							fb.AssertPixel(float4(0, 0, 0, 0), int2(16 + x, 16 + y));
					}
				}
			}
		}
	}
}
