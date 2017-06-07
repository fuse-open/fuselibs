using Uno;
using Uno.Testing;

using Fuse.Navigation;

using FuseTest;

namespace Fuse.Controls.Test
{
	public class PageControlTest : TestBase
	{
		[Test]
		public void ActiveIndex()
		{
			var p = new UX.PageControl.PageIndex();
			var root = TestRootPanel.CreateWithChild(p, int2(100));
			root.StepFrameJS();
			
			//onValueChanged is expected to be called immediately
			Assert.AreEqual( 0, p.PC.ActiveIndex );
			Assert.AreEqual( p.A, p.PC.Active );
			Assert.AreEqual( "0", p.Q.Value );
			Assert.AreEqual( "Page0", p.R.Value );
			
			//the Active/ActiveIndex update immediately, even if the page progress animation is not complete
			p.Goto2.Perform();
			root.StepFrameJS();
			Assert.AreEqual( 2, p.PC.ActiveIndex );
			Assert.AreEqual( p.C, p.PC.Active );
			Assert.AreEqual( "2", p.Q.Value );
			Assert.AreEqual( "Page2", p.R.Value );
			
			p.PC.Active = p.D;
			root.StepFrameJS();
			Assert.AreEqual( 3, p.PC.ActiveIndex );
			Assert.AreEqual( p.D, p.PC.Active );
			Assert.AreEqual( "3", p.Q.Value );
			Assert.AreEqual( "Page3", p.R.Value );
		}
		
		[Test]
		/** Ensures the SwipeNavigate integration is working (see SwipeNavigate.Test.uno for a more complete feature test */
		public void Swipe()
		{
			var p = new UX.PageControl.Swipe();
			var root = TestRootPanel.CreateWithChild(p, int2(1000));
			
			Assert.AreEqual(p.P1,p.Active);
			//swipe left (default to go forward)
			root.PointerSwipe( float2(800,100), float2(100,100), 300 );
			root.StepFrame(5); //stabilize
			Assert.AreEqual(p.P2,p.Active);
		}
		
		[Test]
		//ensure specific distance covered by swiping
		public void SwipeProgress()
		{
			var p = new UX.PageControl.Swipe();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000)))
			{
				Assert.AreEqual(0, (p as INavigation).PageProgress);
				
				(p as INavigation).PageProgressChanged += OnPageProgressChanged;
				
				float speed = 100;
				root.PointerPress( float2(800,200) );
				root.PointerSlide( float2(800,200), float2(550,200), speed);
				//adjust for delayed gesture and accuracy of sliding steps
				Assert.AreEqual(0.25 - Fuse.Input.Gesture.HardCaptureSignificanceThreshold/1000,
					(p as INavigation).PageProgress,
					root.StepIncrement * speed / 1000 + float.ZeroTolerance);
					
				//trying to check jitter https://github.com/fusetools/fuselibs/issues/3597
				//the test doesn't produce "actual" jitter though, but it does detect the extra calls to progress changed
				Assert.IsTrue(_absChangedSum < 0.25);
				Assert.IsTrue(_progressCount < (250/*dist*/ / speed / root.StepIncrement + 1) );
			}
		}
		
		double _absChangedSum;
		int _progressCount;
		void OnPageProgressChanged(object s, NavigationArgs args)
		{
			_progressCount++;
			var diff = args.Progress - args.PreviousProgress;
			_absChangedSum += Math.Abs(diff);
		}
	}
}
