using Uno;
using Uno.Testing;

using Fuse.Triggers;
using Fuse.Triggers.Actions;

using FuseTest;

namespace Fuse.Gestures.Test
{
	public class PointerCaptureTest : TestBase
	{
		[Test]
		public void Active()
		{	
			var p = new UX.PointerCapture.Basic();
			using (var root = TestRootPanel.CreateWithChild(p, int2(1000)))
			{
				Assert.IsFalse(p.PC.IsActive);
				
				root.PointerPress(float2(5,5));
				Assert.IsTrue(p.PC.IsActive);
				
				root.PointerMove(float2(5,30));
				root.PumpDeferred();
				Assert.AreEqual(1, TriggerProgress(p.IA.WH));
				
				root.PointerMove(float2(5,80));
				root.PumpDeferred();
				Assert.AreEqual(0, TriggerProgress(p.IA.WH));
				Assert.AreEqual(1, TriggerProgress(p.IB.WH));
				
				root.PointerRelease(float2(5,82));
				root.PumpDeferred();
				Assert.IsFalse(p.PC.IsActive);
				Assert.AreEqual(0, TriggerProgress(p.IB.WH));
				Assert.AreEqual(1, p.IB.C.PerformedCount);
			}
		}
	}
}
