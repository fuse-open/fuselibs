using Uno;
using Uno.Testing;

using FuseTest;

namespace Fuse.Controls.Panels.Test
{
	public class FreezePanelTest : TestBase
	{
		[Test]
		public void DeferBusy()
		{
			var p = new UX.Freeze.DeferBusy();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.TestDraw();
				Assert.IsFalse(p.FP.TestHasFreezePrepared);

				p.B1.IsBusy = false;
				root.StepFrame(0.5f); //multiple frames
				root.TestDraw();
				Assert.IsTrue(p.FP.TestHasFreezePrepared);
			}
		}

		[Test]
		public void FreezeWithOpacity()
		{
			var tolerance = 1.0f / 255;
			var p = new UX.Freeze.Opacity();
			using (var root = TestRootPanel.CreateWithChild(p, int2(10, 10)))
			{
				// make sure we've drawn a frame first
				p.FreezeMe.IsFrozen = false;
				root.TestDraw();

				using (var fb = root.CaptureDraw())
				{
					fb.AssertPixel(float4(0.5f, 0.5f, 0, 1), int2(5, 5), tolerance);
				}

				// make sure we've drawn a frame first
				p.FreezeMe.IsFrozen = true;
				root.TestDraw();

				using (var fb = root.CaptureDraw())
				{
					fb.AssertPixel(float4(0.5f, 0.5f, 0, 1), int2(5, 5), tolerance);
				}
			}
		}

	}
}
