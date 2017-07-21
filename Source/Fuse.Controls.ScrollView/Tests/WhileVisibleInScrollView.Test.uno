using Uno;
using Uno.Testing;

using FuseTest;

using Fuse.Elements;

namespace Fuse.Controls.ScrollViewTest
{
	public class WhileVisibleInScrollView : TestBase
	{
		[Test]
		public void Basic()
		{
			var sv = new UX.WhileVisibleInScrollView.Basic();
			using (var root = TestRootPanel.CreateWithChild( sv, int2(98) )) //short of 100 to prevent things exactly on edge
			{
				Assert.AreEqual( 0, sv.S.ScrollPosition.Y );
				root.StepFrame(5); //TODO: It's not clear why/if this should be required, it seems to be stabilizing now!

				Assert.AreEqual(1, TriggerProgress(sv.W1.V1) );
				Assert.AreEqual(1, TriggerProgress(sv.W2.V1) );
				Assert.AreEqual(0, TriggerProgress(sv.W3.V1) );
				Assert.AreEqual(0, TriggerProgress(sv.W4.V1) );
				Assert.AreEqual(0, TriggerProgress(sv.W5.V1) );
				
				Assert.AreEqual(1, TriggerProgress(sv.W1.V2) );
				Assert.AreEqual(1, TriggerProgress(sv.W2.V2) );
				Assert.AreEqual(1, TriggerProgress(sv.W3.V2) );
				Assert.AreEqual(0, TriggerProgress(sv.W4.V2) );
				Assert.AreEqual(0, TriggerProgress(sv.W5.V2) );
				
				Assert.AreEqual(1, TriggerProgress(sv.W1.V3) );
				Assert.AreEqual(1, TriggerProgress(sv.W2.V3) );
				Assert.AreEqual(1, TriggerProgress(sv.W3.V3) );
				Assert.AreEqual(1, TriggerProgress(sv.W4.V3) );
				Assert.AreEqual(0, TriggerProgress(sv.W5.V3) );
			
				sv.S.ScrollPosition = float2(0,151);
				root.IncrementFrame();
				
				Assert.AreEqual(0, TriggerProgress(sv.W1.V1) );
				Assert.AreEqual(0, TriggerProgress(sv.W2.V1) );
				Assert.AreEqual(0, TriggerProgress(sv.W3.V1) );
				Assert.AreEqual(1, TriggerProgress(sv.W4.V1) );
				Assert.AreEqual(1, TriggerProgress(sv.W5.V1) );
				
				Assert.AreEqual(0, TriggerProgress(sv.W1.V2) );
				Assert.AreEqual(0, TriggerProgress(sv.W2.V2) );
				Assert.AreEqual(1, TriggerProgress(sv.W3.V2) );
				Assert.AreEqual(1, TriggerProgress(sv.W4.V2) );
				Assert.AreEqual(1, TriggerProgress(sv.W5.V2) );
				
				Assert.AreEqual(0, TriggerProgress(sv.W1.V3) );
				Assert.AreEqual(1, TriggerProgress(sv.W2.V3) );
				Assert.AreEqual(1, TriggerProgress(sv.W3.V3) );
				Assert.AreEqual(1, TriggerProgress(sv.W4.V3) );
				Assert.AreEqual(1, TriggerProgress(sv.W5.V3) );
			}
		}

		[Test]
		public void Mode()
		{
			var sv = new UX.WhileVisibleInScrollView.Mode();
			using (var root = TestRootPanel.CreateWithChild( sv, int2(98) )) //short of 100 to prevent things exactly on edge
			{
				Assert.AreEqual( 0, sv.S.ScrollPosition.Y );
				root.StepFrame(5); //TODO: It's not clear why/if this should be required, it seems to be stabilizing now!

				Assert.AreEqual(1, TriggerProgress(sv.W1.V1) );
				Assert.AreEqual(0, TriggerProgress(sv.W2.V1) );
				Assert.AreEqual(0, TriggerProgress(sv.W3.V1) );
				
				Assert.AreEqual(0, TriggerProgress(sv.W1.V2) );
				Assert.AreEqual(0, TriggerProgress(sv.W2.V2) );
				Assert.AreEqual(0, TriggerProgress(sv.W3.V2) );

				sv.S.ScrollPosition = float2(0,25);
				root.IncrementFrame();
				
				Assert.AreEqual(0, TriggerProgress(sv.W1.V1) );
				Assert.AreEqual(1, TriggerProgress(sv.W2.V1) );
				Assert.AreEqual(0, TriggerProgress(sv.W3.V1) );
				
				Assert.AreEqual(0, TriggerProgress(sv.W1.V2) );
				Assert.AreEqual(1, TriggerProgress(sv.W2.V2) );
				Assert.AreEqual(0, TriggerProgress(sv.W3.V2) );

				sv.S.ScrollPosition = float2(0,52);
				root.IncrementFrame();
				
				Assert.AreEqual(0, TriggerProgress(sv.W1.V1) );
				Assert.AreEqual(0, TriggerProgress(sv.W2.V1) );
				Assert.AreEqual(1, TriggerProgress(sv.W3.V1) );
				
				Assert.AreEqual(0, TriggerProgress(sv.W1.V2) );
				Assert.AreEqual(0, TriggerProgress(sv.W2.V2) );
				Assert.AreEqual(0, TriggerProgress(sv.W3.V2) );
			}
		}
		
		[Test]
		public void Placed()
		{
			var sv = new UX.WhileVisibleInScrollView.Placed();
			using (var root = TestRootPanel.CreateWithChild( sv, int2(100)))
			{
				Assert.AreEqual( 0, sv.V.Progress );
				
				sv.P.Y = 75;
				root.StepFrame();
				Assert.AreEqual( 1, sv.V.Progress );
				
				sv.P.Y = -75;
				root.StepFrame();
				Assert.AreEqual( 0, sv.V.Progress );
			}
		}
		
		[Test]
		public void Bypass()
		{
			var sv = new UX.WhileVisibleInScrollView.Bypass();
			using (var root = TestRootPanel.CreateWithChild( sv, int2(100)))
			{
				Assert.AreEqual( 0, sv.P1.V.Progress );
				Assert.AreEqual( 0, sv.P1.CF.PerformedCount );
				Assert.AreEqual( 0, sv.P1.CB.PerformedCount );
				
				Assert.AreEqual( 1, sv.P2.V.Progress );
				Assert.AreEqual( 0, sv.P2.CF.PerformedCount );
				
				sv.P1.Y = 75;
				root.StepFrame();
				Assert.AreEqual( 0, sv.P1.V.Progress, root.StepIncrement + Assert.ZeroTolerance);
				Assert.AreEqual( 1, sv.P1.CF.PerformedCount );
				Assert.AreEqual( 0, sv.P1.CB.PerformedCount );
				
				root.StepFrame(1);
				Assert.AreEqual( 1, sv.P1.V.Progress );
				
				sv.P2.Y = 200;
				root.StepFrame();
				Assert.AreEqual( 1, sv.P2.V.Progress, root.StepIncrement + Assert.ZeroTolerance);
				Assert.AreEqual( 0, sv.P2.CF.PerformedCount );
				Assert.AreEqual( 1, sv.P2.CB.PerformedCount );
				
				root.StepFrame(1);
				Assert.AreEqual( 0, sv.P2.V.Progress );
			}
		}
	}
}
