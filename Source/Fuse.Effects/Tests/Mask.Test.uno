using Uno;
using Uno.Compiler;
using Uno.Testing;

using FuseTest;

namespace Fuse.Effects.Test
{
	public class MaskTest : TestBase
	{
		[Test]
		public void MaskRGBAWithWhite()
		{
			var p = new global::UX.MaskRGBAWithWhite();
			using (var root = TestRootPanel.CreateWithChild(p, int2(10)))
			{
				using (var fb = root.CaptureDraw())
				{
					fb.AssertPixel(float4(1, 0, 0, 1), int2(2, 2));
					fb.AssertPixel(float4(0, 1, 0, 1), int2(7, 2));
					fb.AssertPixel(float4(0, 0, 1, 1), int2(2, 7));
					fb.AssertPixel(float4(0, 0, 0, 0), int2(7, 7));
				}
			}
		}

		[Test]
		public void MaskPositioning()
		{
			var p = new global::UX.MaskPositioning();
			using (var root = TestRootPanel.CreateWithChild(p, int2(10, 30)))
			{
				using (var fb = root.CaptureDraw())
				{
					fb.AssertPixel(float4(1, 0, 0, 1), int2(2, 22));
					fb.AssertPixel(float4(0, 1, 0, 1), int2(7, 22));
					fb.AssertPixel(float4(0, 0, 1, 1), int2(2, 27));
					fb.AssertPixel(float4(0, 0, 0, 0), int2(7, 27));

					fb.AssertPixel(float4(0, 0, 0, 0), int2(2, 12));
					fb.AssertPixel(float4(0, 1, 0, 1), int2(7, 12));
					fb.AssertPixel(float4(0, 0, 0, 0), int2(2, 17));
					fb.AssertPixel(float4(0, 0, 0, 0), int2(7, 17));

					fb.AssertPixel(float4(1, 0, 0, 1), int2(2, 2));
					fb.AssertPixel(float4(0, 0, 0, 0), int2(7, 2));
					fb.AssertPixel(float4(0, 0, 1, 1), int2(2, 7));
					fb.AssertPixel(float4(0, 0, 0, 0), int2(7, 7));
				}
			}
		}
	}
}
