using Uno;
using Uno.Testing;

using Fuse.Triggers;

using FuseTest;

namespace Fuse.Gestures.Test
{
	public class ClickedTest : TestBase
	{
		[Test]
		//Clicked uses soft-captures, so it's possible for all them in a stack to activate
		public void Stacked()
		{	
			var p = new UX.Clicked.Stacked();
			using (var root = TestRootPanel.CreateWithChild(p, int2(1000)))
			{
				root.PointerSwipe( float2(35), float2(35) );
				Assert.AreEqual( 1, p.C1.PerformedCount );
				Assert.AreEqual( 1, p.C2.PerformedCount );
				Assert.AreEqual( 1, p.C3.PerformedCount );
				
				root.PointerSwipe( float2(25), float2(25) );
				Assert.AreEqual( 2, p.C1.PerformedCount );
				Assert.AreEqual( 2, p.C2.PerformedCount );
				Assert.AreEqual( 1, p.C3.PerformedCount );
				
				root.PointerSwipe( float2(15), float2(35) );
				Assert.AreEqual( 3, p.C1.PerformedCount ); //only one that got the pointerdown
				Assert.AreEqual( 2, p.C2.PerformedCount );
				Assert.AreEqual( 1, p.C3.PerformedCount );
			}
		}
		
		[Test]
		public void Basic()
		{
			var p = new UX.Clicked.Basic();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000)))
			{
				root.PointerSwipe(float2(5), float2(5));
				Assert.AreEqual( 1, p.C1.PerformedCount );
				
				root.PointerSwipe(float2(5), float2(15)); //swipe outside
				Assert.AreEqual( 1, p.C1.PerformedCount );
				
				root.PointerSwipe(float2(2), float2(9)); //swipe inside
				Assert.AreEqual( 2, p.C1.PerformedCount );
				
				root.PointerSwipe(float2(15), float2(5)); //swipe into
				Assert.AreEqual( 2, p.C1.PerformedCount );
				
				//out-in again
				root.PointerPress(float2(5));
				root.PointerSlide(float2(5),float2(15),5);
				root.PointerRelease(float2(9));
				Assert.AreEqual( 3, p.C1.PerformedCount );
			}
		}
		
		[Test]
		public void ScrollView()
		{
			var p = new UX.Clicked.ScrollView();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000)))
			{
				root.PointerSwipe( float2(100,120), float2(100,120));
				Assert.AreEqual( 1, p.C1.PerformedCount );
				Assert.AreEqual( 0, p.SV.ScrollPosition.Y );
				
				//scrolls, not clicks (though pointer remains within button the whole time)
				root.PointerSwipe( float2(100,140), float2(100, 50));
				Assert.AreEqual( 1, p.C1.PerformedCount );
				Assert.IsTrue( p.SV.ScrollPosition.Y > 0 );
			}
		}
		
		[Test]
		//https://github.com/fusetools/ManualTestApp/issues/348
		public void NoCaptureBlock()
		{
			var p = new UX.Clicked.NoCaptureBlock();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000)))
			{
				root.PointerPress( float2(50,50) );
				root.StepFrame();
				
				root.PointerPress( float2(950,50), 1 );
				root.StepFrame(0.2f);
				root.PointerRelease( float2(950,50), 1 );
				
				Assert.AreEqual( 1, p.C.PerformedCount );
			}
		}
	}
}
