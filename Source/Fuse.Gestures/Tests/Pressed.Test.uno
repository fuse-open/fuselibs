using Uno;
using Uno.Testing;

using Fuse.Triggers;

using FuseTest;

namespace Fuse.Gestures.Test
{
	public class PressedTest : TestBase
	{
		[Test]
		public void Basic()
		{	
			var p = new UX.Pressed.Basic();
			using (var root = TestRootPanel.CreateWithChild(p, int2(200)))
			{
				root.PointerPress(float2(50,50));
				Assert.AreEqual( 1, TriggerProgress(p.P1.WP));
				Assert.AreEqual( 1, p.P1.CP.PerformedCount );
				Assert.AreEqual( 0, p.P1.CR.PerformedCount );
				
				root.PointerRelease(float2(50,50));
				Assert.AreEqual( 0, TriggerProgress(p.P1.WP));
				Assert.AreEqual( 1, p.P1.CP.PerformedCount );
				Assert.AreEqual( 1, p.P1.CR.PerformedCount );
				
				
				//cross from one to the other
				root.PointerPress(float2(50,50));
				Assert.AreEqual( 1, TriggerProgress(p.P1.WP));
				Assert.AreEqual( 2, p.P1.CP.PerformedCount );
				Assert.AreEqual( 1, p.P1.CR.PerformedCount );
				
				Assert.AreEqual( 0, TriggerProgress(p.P2.WP));
				Assert.AreEqual( 0, p.P2.CP.PerformedCount );
				Assert.AreEqual( 0, p.P2.CR.PerformedCount );
				
				root.PointerSlide(float2(50,50), float2(150,50), 100);
				Assert.AreEqual( 0, TriggerProgress(p.P1.WP));
				Assert.AreEqual( 1, TriggerProgress(p.P2.WP));
				
				root.PointerRelease(float2(150,50));
				Assert.AreEqual( 0, TriggerProgress(p.P1.WP));
				Assert.AreEqual( 2, p.P1.CP.PerformedCount );
				Assert.AreEqual( 1, p.P1.CR.PerformedCount );
				
				Assert.AreEqual( 0, TriggerProgress(p.P2.WP));
				Assert.AreEqual( 0, p.P2.CP.PerformedCount );
				Assert.AreEqual( 1, p.P2.CR.PerformedCount );
			}
		}
		
		[Test]
		public void Capture()
		{	
			var p = new UX.Pressed.Capture();
			using (var root = TestRootPanel.CreateWithChild(p, int2(200)))
			{
				root.PointerPress(float2(50,50));
				Assert.AreEqual( 1, TriggerProgress(p.P1.WP));
				Assert.AreEqual( 1, p.P1.CP.PerformedCount );
				Assert.AreEqual( 0, p.P1.CR.PerformedCount );
				
				root.PointerRelease(float2(50,50));
				Assert.AreEqual( 0, TriggerProgress(p.P1.WP));
				Assert.AreEqual( 1, p.P1.CP.PerformedCount );
				Assert.AreEqual( 1, p.P1.CR.PerformedCount );
				
				
				//cross from one to the other
				root.PointerPress(float2(50,50));
				Assert.AreEqual( 1, TriggerProgress(p.P1.WP));
				Assert.AreEqual( 2, p.P1.CP.PerformedCount );
				Assert.AreEqual( 1, p.P1.CR.PerformedCount );
				
				Assert.AreEqual( 0, TriggerProgress(p.P2.WP));
				Assert.AreEqual( 0, p.P2.CP.PerformedCount );
				Assert.AreEqual( 0, p.P2.CR.PerformedCount );
				
				root.PointerSlide(float2(50,50), float2(150,50), 100);
				Assert.AreEqual( 0, TriggerProgress(p.P1.WP));
				Assert.AreEqual( 0, TriggerProgress(p.P2.WP));
				
				root.PointerRelease(float2(150,50));
				Assert.AreEqual( 0, TriggerProgress(p.P1.WP));
				Assert.AreEqual( 2, p.P1.CP.PerformedCount );	
				Assert.AreEqual( 2, p.P1.CR.PerformedCount );//TODO: is this perhaps a defect. It's not longer in bounds, but does get a released event
				
				Assert.AreEqual( 0, TriggerProgress(p.P2.WP));
				Assert.AreEqual( 0, p.P2.CP.PerformedCount );
				Assert.AreEqual( 0, p.P2.CR.PerformedCount );
			}
		}
	}
}
