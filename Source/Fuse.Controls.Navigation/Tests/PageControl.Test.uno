using Uno;
using Uno.Testing;

using Fuse.Navigation;

using FuseTest;

namespace Fuse.Controls.Test
{
	public class PageControlTest : TestBase
	{
		[Test]
		public void ActiveIndexBasic()
		{
			var p = new UX.PageControl.PageIndex();
			using (var root = TestRootPanel.CreateWithChild(p, int2(100)))
			{
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

				p.Seek1.Perform();
				root.StepFrameJS();
				Assert.AreEqual( 1, p.PC.ActiveIndex );
				Assert.AreEqual( p.B, p.PC.Active );
				Assert.AreEqual( "1", p.Q.Value );
				Assert.AreEqual( "Page1", p.R.Value );
				
				p.RouteGoto4.Pulse();
				root.MultiStepFrameJS(2);
				Assert.AreEqual( 3, p.PC.ActiveIndex );
				Assert.AreEqual( p.D, p.PC.Active );
				Assert.AreEqual( "3", p.Q.Value );
				Assert.AreEqual( "Page3", p.R.Value );
			}
		}
		
		[Test]
		/** Ensures the SwipeNavigate integration is working (see SwipeNavigate.Test.uno for a more complete feature test */
		public void Swipe()
		{
			var p = new UX.PageControl.Swipe();
			using (var root = TestRootPanel.CreateWithChild(p, int2(1000)))
			{
				Assert.AreEqual(p.P1,p.Active);
				//swipe left (default to go forward)
				root.PointerSwipe( float2(800,100), float2(100,100), 300 );
				root.StepFrame(5); //stabilize
				Assert.AreEqual(p.P2,p.Active);
			}
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
				const float ZeroTolerance = 1e-05f;
				Assert.AreEqual(0.25 - Fuse.Input.Gesture.HardCaptureSignificanceThreshold/1000,
					(p as INavigation).PageProgress,
					root.StepIncrement * speed / 1000 + ZeroTolerance);
					
				//trying to check jitter https://github.com/fusetools/fuselibs-private/issues/3597
				//the test doesn't produce "actual" jitter though, but it does detect the extra calls to progress changed
				Assert.IsTrue(_absChangedSum < 0.25);
				Assert.IsTrue(_progressCount < (250/*dist*/ / speed / root.StepIncrement + 1) );
			}
		}

		string SafeFormat( RouterPageRoute r )
		{
			if (r == null) 
				return "*null*";
			return r.Format();
		}

		[Test]
		//tests history through a local Active change
		public void History()
		{
			var p = new UX.PageControl.History();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual("a/i", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(1));
				Assert.AreEqual( 0, p.wcb.Progress );

				p.router.Push( new Route("a", null, new Route("ii") ) );
				root.StepFrame();
				Assert.AreEqual("a/ii", SafeFormat(p.router.GetHistoryRoute(0)));
				Assert.AreEqual("a/i", SafeFormat(p.router.GetHistoryRoute(1)));
				Assert.AreEqual( null, p.router.GetHistoryRoute(2));
				Assert.AreEqual( 1, p.wcb.Progress );

				p.pc.Active = p.b;
				root.StepFrame();
				Assert.AreEqual("b", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(1));
				Assert.AreEqual( 0, p.wcb.Progress );

				p.pc.Active = p.a;
				root.StepFrame();
				Assert.AreEqual("a/ii", SafeFormat(p.router.GetHistoryRoute(0)));
				Assert.AreEqual("a/i", SafeFormat(p.router.GetHistoryRoute(1)));
				Assert.AreEqual( null, p.router.GetHistoryRoute(2));
				Assert.AreEqual( 1, p.wcb.Progress );

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
		
		[Test]
		public void DynamicActiveIndex()
		{
			var p = new UX.PageControl.DynamicActiveIndex();
			using (var root = TestRootPanel.CreateWithChild(p, int2(1000)))
			{
				//give any changes to ActiveIndex a chance to propagate in both directions
				root.StepFrameJS();
				root.StepFrameJS(); 
				Assert.AreEqual( 2, p.index.Value );
				
				p.callAdd.Perform();
				root.StepFrameJS();
				Assert.AreEqual( 2, p.index.Value );
				
				p.goForward.Pulse();
				root.StepFrame(5);
				root.StepFrameJS();
				Assert.AreEqual( 1, p.index.Value );
				
				//swipe left (default to go forward)
				root.PointerSwipe( float2(100,100), float2(800,100), 300 );
				root.StepFrame(5); //stabilize
				root.StepFrameJS();
				Assert.AreEqual( 0, p.index.Value );
			}
		}
		
		[Test]
		public void Active()
		{
			var p = new UX.PageControl.Active();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( p.p2, p.pc1.Active );
				Assert.AreEqual( 1, p.p2.wa.Progress );
				Assert.AreEqual( 1, p.p2.an.Progress );
				Assert.AreEqual( 0, p.p1.wa.Progress );
				Assert.AreEqual( 0, p.p1.an.Progress );
			}
		}
		
		[Test]
		//ensuring it works without content
		public void Empty()
		{
			var p = new UX.PageControl.Empty();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( null, p.pc.Active );
			}
		}
		
		[Test]
		public void WhileTrigger()
		{
			var p = new UX.PageControl.WhileTrigger();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( p.pa, p.nav.Active );
				Assert.AreEqual( 0, p.wf1.Progress );
				Assert.AreEqual( 1, p.wb1.Progress );
				Assert.AreEqual( 0, p.wf2.Progress );
				Assert.AreEqual( 1, p.wb2.Progress );
				
				p.nav.GoBack();
				root.PumpDeferred();
				Assert.AreEqual( p.pb, p.nav.Active );
				Assert.AreEqual( 1, p.wf1.Progress );
				Assert.AreEqual( 1, p.wb1.Progress );
				Assert.AreEqual( 1, p.wf2.Progress );
				Assert.AreEqual( 1, p.wb2.Progress );
				
				p.nav.GoBack();
				root.PumpDeferred();
				Assert.AreEqual( p.pc, p.nav.Active );
				Assert.AreEqual( 1, p.wf1.Progress );
				Assert.AreEqual( 0, p.wb1.Progress );
				Assert.AreEqual( 1, p.wf2.Progress );
				Assert.AreEqual( 0, p.wb2.Progress );
				
				p.nav.GoForward();
				root.PumpDeferred();
				Assert.AreEqual( p.pb, p.nav.Active );
				Assert.AreEqual( 1, p.wf1.Progress );
				Assert.AreEqual( 1, p.wb1.Progress );
				Assert.AreEqual( 1, p.wf2.Progress );
				Assert.AreEqual( 1, p.wb2.Progress );
			}
		}
		
		[Test]
		//variant without a PageControl.Active set initially
		public void WhileTrigger2()
		{
			var p = new UX.PageControl.WhileTrigger2();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( p.pa, p.nav.Active );
				Assert.AreEqual( 0, p.wf1.Progress );
				Assert.AreEqual( 1, p.wb1.Progress );
				Assert.AreEqual( 0, p.wf2.Progress );
				Assert.AreEqual( 1, p.wb2.Progress );
				
				p.nav.GoBack();
				root.PumpDeferred();
				Assert.AreEqual( p.pb, p.nav.Active );
				Assert.AreEqual( 1, p.wf1.Progress );
				Assert.AreEqual( 1, p.wb1.Progress );
				Assert.AreEqual( 1, p.wf2.Progress );
				Assert.AreEqual( 1, p.wb2.Progress );
			}
		}
		
		[Test]
		public void WhileActive()
		{
			var p = new UX.PageControl.WhileActive();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( 1, p.paA.Progress );
				Assert.AreEqual( 0, p.pbA.Progress );
				Assert.AreEqual( 0, p.pcA.Progress );
				
				p.nav.GoBack();
				root.StepFrame();
				Assert.AreEqual( 0, p.paA.Progress );
				Assert.AreEqual( 1, p.pbA.Progress );
				Assert.AreEqual( 0, p.pcA.Progress );
				
				p.nav.GoBack();
				root.StepFrame();
				Assert.AreEqual( 0, p.paA.Progress );
				Assert.AreEqual( 0, p.pbA.Progress );
				Assert.AreEqual( 1, p.pcA.Progress );
				
				p.nav.GoForward();
				root.StepFrame();
				Assert.AreEqual( 0, p.paA.Progress );
				Assert.AreEqual( 1, p.pbA.Progress );
				Assert.AreEqual( 0, p.pcA.Progress );
			}
		}
		
		[Test]
		//by default inactive pages will be collapsed
		public void Visibility()
		{
			var p = new UX.PageControl.Visibility();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( Fuse.Elements.Visibility.Visible, p.pa.Visibility );
				Assert.AreEqual( Fuse.Elements.Visibility.Collapsed, p.pb.Visibility );
				Assert.AreEqual( Fuse.Elements.Visibility.Collapsed, p.pc.Visibility );
				Assert.AreEqual( 1, p.pav.Progress );
				Assert.AreEqual( 0, p.pbv.Progress );
				Assert.AreEqual( 0, p.pcv.Progress );
				
				p.nav.Active = p.pb;
				root.StepFrame(0.1f); //just a bit, both visible
				Assert.AreEqual( Fuse.Elements.Visibility.Visible, p.pa.Visibility );
				Assert.AreEqual( Fuse.Elements.Visibility.Visible, p.pb.Visibility );
				Assert.AreEqual( Fuse.Elements.Visibility.Collapsed, p.pc.Visibility );
				Assert.AreEqual( 1, p.pav.Progress );
				Assert.AreEqual( 1, p.pbv.Progress );
				Assert.AreEqual( 0, p.pcv.Progress );
				
				root.StepFrame(1); //complete animation
				Assert.AreEqual( Fuse.Elements.Visibility.Collapsed, p.pa.Visibility );
				Assert.AreEqual( Fuse.Elements.Visibility.Visible, p.pb.Visibility );
				Assert.AreEqual( Fuse.Elements.Visibility.Collapsed, p.pc.Visibility );
				Assert.AreEqual( 0, p.pav.Progress );
				Assert.AreEqual( 1, p.pbv.Progress );
				Assert.AreEqual( 0, p.pcv.Progress );
			}
		}
		
		[Test]
		public void PagesBasic()
		{
			var p = new UX.PageControl.Pages();
			FuseTest.InstanceCounter.Reset();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual("one", GetRecursiveText(p.pc.Active));
				//ensure the Template instantiation isn't overdone
				Assert.AreEqual( 3, FuseTest.InstanceCounter.Count );
				Assert.AreEqual( 3, GetChildren<Page>(p.pc).Length );
				
				p.goto1.Perform();
				root.StepFrameJS();
				Assert.AreEqual("two", GetRecursiveText(p.pc.Active));
				Assert.AreEqual( 3, FuseTest.InstanceCounter.Count );
			}
		}
		
		[Test]
		//trying to get the Pages value known at rooting time to invoke other code paths
		public void PagesRoot()
		{
			var p = new UX.PageControl.PagesRoot();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				
				p.w.Value = true;
				root.StepFrameJS();
				Assert.AreEqual("one", GetRecursiveText(p.pc.Active));
				
				p.goto1.Perform();
				root.StepFrameJS();
				Assert.AreEqual("two", GetRecursiveText(p.pc.Active));
			}
		}
		
		[Test]
		public void PagesChange()
		{
			var p = new UX.PageControl.PagesChange();
			FuseTest.InstanceCounter.Reset();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual("one,two,three", GetRecursiveText(p.pc));
				Assert.AreEqual("two", GetRecursiveText(p.pc.Active));
				Assert.AreEqual( 3, FuseTest.InstanceCounter.Count );
				
				p.callAdd.Perform();
				root.StepFrameJS();
				Assert.AreEqual("one,two,three,four", GetRecursiveText(p.pc));
				Assert.AreEqual("two", GetRecursiveText(p.pc.Active));
				Assert.AreEqual( 4, FuseTest.InstanceCounter.Count );
				
				p.callInsert.Perform();
				root.StepFrameJS();
				Assert.AreEqual("five,one,two,three,four", GetRecursiveText(p.pc));
				//Index is considered the dominant selector, thus the active page changes
				Assert.AreEqual("one", GetRecursiveText(p.pc.Active));
				Assert.AreEqual( 5, FuseTest.InstanceCounter.Count );
				
				p.callRemove.Perform();
				root.StepFrameJS();
				Assert.AreEqual("five,three,four", GetRecursiveText(p.pc));
				Assert.AreEqual("three", GetRecursiveText(p.pc.Active));
				Assert.AreEqual( 5, FuseTest.InstanceCounter.Count );
			}
		}
		
		[Test]
		public void PageHistory()
		{
			var p = new UX.PageControl.PageHistory();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual( p.b, p.pc.Active );
			}
		}
		
		[Test]
		public void ActiveStringBinding()
		{
			var p = new UX.PageControl.ActiveStringBinding();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual( "222", ((string)p.pc.Active.Name) );
			}
		}
	}
}
