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
			var root = TestRootPanel.CreateWithChild(p, int2(10));
			root.CaptureDraw();

			Assert.AreEqual(float4(1, 0, 0, 1), root.ReadDrawPixel(2, 2));
			Assert.AreEqual(float4(0, 1, 0, 1), root.ReadDrawPixel(7, 2));
			Assert.AreEqual(float4(0, 0, 1, 1), root.ReadDrawPixel(2, 7));
			Assert.AreEqual(float4(0, 0, 0, 0), root.ReadDrawPixel(7, 7));
		}

		[Test]
		public void MaskPositioning()
		{
			var p = new global::UX.MaskPositioning();
			var root = TestRootPanel.CreateWithChild(p, int2(10, 30));
			root.CaptureDraw();

			Assert.AreEqual(float4(1, 0, 0, 1), root.ReadDrawPixel(2, 22));
			Assert.AreEqual(float4(0, 1, 0, 1), root.ReadDrawPixel(7, 22));
			Assert.AreEqual(float4(0, 0, 1, 1), root.ReadDrawPixel(2, 27));
			Assert.AreEqual(float4(0, 0, 0, 0), root.ReadDrawPixel(7, 27));

			Assert.AreEqual(float4(0, 0, 0, 0), root.ReadDrawPixel(2, 12));
			Assert.AreEqual(float4(0, 1, 0, 1), root.ReadDrawPixel(7, 12));
			Assert.AreEqual(float4(0, 0, 0, 0), root.ReadDrawPixel(2, 17));
			Assert.AreEqual(float4(0, 0, 0, 0), root.ReadDrawPixel(7, 17));

			Assert.AreEqual(float4(1, 0, 0, 1), root.ReadDrawPixel(2, 2));
			Assert.AreEqual(float4(0, 0, 0, 0), root.ReadDrawPixel(7, 2));
			Assert.AreEqual(float4(0, 0, 1, 1), root.ReadDrawPixel(2, 7));
			Assert.AreEqual(float4(0, 0, 0, 0), root.ReadDrawPixel(7, 7));
		}
	}
}
