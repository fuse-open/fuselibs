using Uno;
using Uno.Testing;
using Uno.UX;

using FuseTest;

namespace Fuse.Controls.Primitives.Test
{
	public class CircleTest : TestBase
	{
		[Test]
		public void Rendering()
		{
			var p = new UX.Circle.Rendering();
			using (var root = TestRootPanel.CreateWithChild(p, int2(10, 10)))
			using (var fb = root.CaptureDraw())
			{
				fb.AssertPixel(float4(1, 0, 0, 1), int2(5, 5));

				var center = float2(5f, 5f);
				var radius = 2.5f;
				for (int y = 0; y < 10; ++y)
				{
					for (int x = 0; x < 10; ++x)
					{
						var pos = int2(x, y);
						float distance = Vector.Distance(center, pos + float2(0.5f, 0.5f));
						float alpha = Math.Saturate(radius - distance + 0.5f);
						fb.AssertPixel(float4(alpha, 0, 0, alpha), pos, 2.0f / 255);
					}
				}
			}
		}
	}
}
