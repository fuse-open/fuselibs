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
	}
}
