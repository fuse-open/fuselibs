using Uno;
using Uno.Testing;
using Fuse;
using FuseTest;

namespace Fuse.Test
{
	public class RenderingTest : TestBase
	{
		[Test]
		public void NestedClipToBounds()
		{
			var p = new UX.Rendering.NestedClipToBounds();
			using (var root = TestRootPanel.CreateWithChild(p, int2(32, 32)))
			using (var fb = root.CaptureDraw())
			{
				fb.AssertSolidRectangle(float4(0, 0, 0, 0), new Recti(0, 0, 32, 16));

				fb.AssertSolidRectangle(float4(0, 0, 0, 0), new Recti(0, 16, 16, 24));
				fb.AssertSolidRectangle(float4(1, 0, 0, 1), new Recti(16, 16, 24, 24));
				fb.AssertSolidRectangle(float4(0, 0, 0, 0), new Recti(24, 16, 32, 24));

				fb.AssertSolidRectangle(float4(0, 0, 0, 0), new Recti(0, 24, 32, 32));
			}
		}
	}
}
