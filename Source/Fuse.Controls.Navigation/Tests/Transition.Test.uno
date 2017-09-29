using Uno;
using Uno.Testing;
using Uno.UX;

using FuseTest;

using Fuse.Elements;
using Fuse.Triggers;
using Fuse.Triggers.Actions;

namespace Fuse.Navigation.Test
{
	public class TransitionTest : TestBase
	{
		const float _zeroTolerance = 1e-05f;

		[Test]
		public void Basic()
		{
			var p = new UX.Transition.Basic();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrame();

				var one0 = p.nav.Active as TBPage;

				p.router.Push( new Route("two", "1"));
				root.StepFrame();
				var two1 = p.nav.Active as TBPage;

				Assert.AreEqual(1,one0.f1.PerformedCount);
				Assert.AreEqual(0,one0.b1.PerformedCount);

				Assert.AreEqual(0,two1.f2.PerformedCount);
				Assert.AreEqual(1,two1.b2.PerformedCount);

				p.router.Push( new Route("one", "2"));
				root.StepFrame();
				var one2 = p.nav.Active as TBPage;

				Assert.AreEqual(0,one2.f1.PerformedCount);
				Assert.AreEqual(0,one2.b1.PerformedCount);
				Assert.AreEqual(1,one2.b3.PerformedCount);

				Assert.AreEqual(0,two1.f2.PerformedCount);
				Assert.AreEqual(1,two1.b2.PerformedCount);

				p.router.GoBack();
				root.StepFrame();

				Assert.AreEqual(two1, p.nav.Active);

				Assert.AreEqual(0,one2.f1.PerformedCount);
				Assert.AreEqual(0,one2.b1.PerformedCount);
				Assert.AreEqual(1,one2.b3.PerformedCount);
				Assert.AreEqual(1,one2.f4.PerformedCount);

				Assert.AreEqual(0,two1.f2.PerformedCount);
				Assert.AreEqual(1,two1.b2.PerformedCount);

				p.router.GoBack();
				root.StepFrame();

				Assert.AreEqual(one0, p.nav.Active);
				Assert.AreEqual(1,one0.f1.PerformedCount);
				Assert.AreEqual(1,one0.b1.PerformedCount);

				Assert.AreEqual(1,two1.f2.PerformedCount);
				Assert.AreEqual(1,two1.b2.PerformedCount);

				root.Children.Remove(p);
				Assert.AreEqual(0, TransitionGroup.TestMemoryCount );
			}
		}
		
		[Test]
		//checks some basic with non-template pages and with Bypass mode
		public void BasicNonTemplate()
		{
			var p = new UX.Transition.BasicNonTemplate();
			using(var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(p.one, p.nav.Active);
				Assert.AreEqual(0, TriggerProgress(p.one.t4));
				Assert.AreEqual(0, TriggerProgress(p.one.t5));
				Assert.AreEqual(0, TriggerProgress(p.two.t5));
				Assert.AreEqual(1, TriggerProgress(p.two.t4));
				
				//was all in bypass, thus no counts
				Assert.AreEqual(0, p.one.f4.PerformedCount);
				Assert.AreEqual(0, p.one.b4.PerformedCount);
				Assert.AreEqual(0, p.two.f4.PerformedCount);
				Assert.AreEqual(0, p.two.b4.PerformedCount);

				p.router.Push( new Route("two"));
				root.StepFrame();
				Assert.AreEqual(p.two, p.nav.Active);

				Assert.AreEqual(1,p.one.f1.PerformedCount);
				Assert.AreEqual(0,p.one.b1.PerformedCount);

				Assert.AreEqual(0,p.two.f2.PerformedCount);
				Assert.AreEqual(1,p.two.b2.PerformedCount);
				Assert.AreEqual(0,p.two.f4.PerformedCount);
				Assert.AreEqual(0,p.two.b4.PerformedCount);

				root.StepFrame(5); //stabilize
				Assert.AreEqual(1,TriggerProgress(p.one.t1));
				Assert.AreEqual(0,TriggerProgress(p.one.t2));
				Assert.AreEqual(0,TriggerProgress(p.one.t3));
				Assert.AreEqual(0,TriggerProgress(p.one.t4));
				Assert.AreEqual(0,TriggerProgress(p.one.t5));

				Assert.AreEqual(0,TriggerProgress(p.two.t1));
				Assert.AreEqual(0,TriggerProgress(p.two.t2));
				Assert.AreEqual(0,TriggerProgress(p.two.t3));
				Assert.AreEqual(0,TriggerProgress(p.two.t4));
				Assert.AreEqual(0,TriggerProgress(p.two.t5));

				p.router.Push( new Route("one"));
				root.StepFrame();
				Assert.AreEqual(p.one, p.nav.Active);

				root.Children.Remove(p);
				Assert.AreEqual(0, TransitionGroup.TestMemoryCount );
			}
		}
		
		[Test]
		public void FrontBack()
		{
			var p = new UX.Transition.FrontBack();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrame();

				var p0 = p.nav.Active as TFBPage;

				p.router.Push( new Route("one", "1"));
				root.StepFrame();
				var p1 = p.nav.Active as TFBPage;

				Assert.AreEqual(1,p0.fToBack.PerformedCount);
				Assert.AreEqual(1,p1.bFromFront.PerformedCount);

				p.router.GoBack();
				root.StepFrame();

				Assert.AreEqual(1,p0.bFromBack.PerformedCount);
				Assert.AreEqual(1,p1.fToFront.PerformedCount);

				Assert.AreEqual(2, TotalActionCount(p0));
				Assert.AreEqual(2, TotalActionCount(p1));
			}
		}
		
		[Test]
		public void InFrontBehind()
		{
			var p = new UX.Transition.InFrontBehind();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrame();

				var p0 = p.nav.Active as TIFBPage;

				p.router.Push( new Route("one", "1"));
				root.StepFrame();
				var p1 = p.nav.Active as TIFBPage;

				Assert.AreEqual(1,p0.fBehind.PerformedCount);
				Assert.AreEqual(1,p1.bInFront.PerformedCount);

				p.router.GoBack();
				root.StepFrame();

				Assert.AreEqual(1,p0.bBehind.PerformedCount);
				Assert.AreEqual(1,p1.fInFront.PerformedCount);

				Assert.AreEqual(2, TotalActionCount(p0));
				Assert.AreEqual(2, TotalActionCount(p1));
			}
		}

		/* 
			Sums all FuseTest.CountAction counts of the child triggers. This simplifies tests to only checking what has
			changed/is non-zero.
		*/
		int TotalActionCount(Visual v)
		{
			int c =0;
			for (int i=0; i < v.Children.Count; ++i)
			{
				var t = v.Children[i] as Trigger;
				if (t == null)	
					continue;
					
				for (int j=0; j < t.Actions.Count; ++j)
				{
					var ta = t.Actions[j] as FuseTest.CountAction;
					if (ta != null)
						c += ta.PerformedCount;
				}
			}
			
			return c;
		}
		
		[Test]
		public void Release()
		{
			var p = new UX.Transition.Release();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrame();

				var p0 = p.nav.Active as TRPage;

				p.router.Push( new Route("one", "1"));
				root.StepFrame(1.1f);
				var p1 = p.nav.Active as TRPage;

				Assert.IsFalse(p.nav.Children.Contains(p0));
				Assert.IsTrue(p.nav.Children.Contains(p1));

				p.router.Push( new Route("popup", "2"));
				root.StepFrame(1.1f);
				var p2 = p.nav.Active as TRPage;

				Assert.IsTrue(p.nav.Children.Contains(p1));
			}
		}
		
		[Test]
		public void Interactive()
		{
			var p = new UX.Transition.Interactive();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000)))
			{
				p.router.Push( new Route( "two" ) );
				root.StepFrame(0.5f);
				var eps = root.StepIncrement + _zeroTolerance;
				Assert.AreEqual(0.5f, TriggerProgress(p.one.T2), eps);
				Assert.AreEqual(0.5f, TriggerProgress(p.two.T2), eps);
				Assert.AreEqual(0f, TriggerProgress(p.one.T1), eps);
				Assert.AreEqual(0f, TriggerProgress(p.two.T1), eps);
				root.StepFrame(1); //stabilize
				
				root.PointerPress(float2(100,100));
				root.PointerSlide(float2(100,100), float2(600+GestureHardCaptureSignificanceThreshold,100),200);
				Assert.AreEqual(0f, TriggerProgress(p.one.T2), eps);
				Assert.AreEqual(0f, TriggerProgress(p.two.T2), eps);
				Assert.AreEqual(0.5f, TriggerProgress(p.one.T1), eps);
				Assert.AreEqual(0.5f, TriggerProgress(p.two.T1), eps);
				
				root.PointerRelease(float2(600+GestureHardCaptureSignificanceThreshold,100));
				root.StepFrame(5); //stabilize
				Assert.AreEqual(0f, TriggerProgress(p.one.T2), eps);
				Assert.AreEqual(0f, TriggerProgress(p.two.T2), eps);
				Assert.AreEqual(1f, TriggerProgress(p.one.T1), eps);
				Assert.AreEqual(0f, TriggerProgress(p.two.T1), eps);
			}
		}
		
		[Test]
		//tests operation style matching
		public void Style()
		{
			var p = new UX.Transition.Style();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				p.BangTwo.Perform();
				root.StepFrameJS();
				//get a base time, 1-2 frames anim is acceptable on sync
				var b = (float)TriggerProgress(p.one.T1);
				Assert.IsTrue( b < (2 * root.StepIncrement + _zeroTolerance) );
				root.StepFrame(0.4f - b);
				
				Assert.AreEqual(0.4f, TriggerProgress(p.one.T1));
				Assert.AreEqual(0f, TriggerProgress(p.one.T2));
				Assert.AreEqual(0f, TriggerProgress(p.one.T3));
				Assert.AreEqual(0.6f, TriggerProgress(p.two.T1));
				Assert.AreEqual(0f, TriggerProgress(p.two.T2));
				Assert.AreEqual(0f, TriggerProgress(p.two.T3));
				root.StepFrame(2); //stabilize
				
				
				p.FlashOne.Perform();
				root.StepFrameJS();
				b = (float)TriggerProgress(p.two.T3);
				Assert.IsTrue( b < (2 * root.StepIncrement + _zeroTolerance) );
				root.StepFrame(0.4f - b);
				
				Assert.AreEqual(0f, TriggerProgress(p.one.T1));
				Assert.AreEqual(0f, TriggerProgress(p.one.T2));
				Assert.AreEqual(0.6f, TriggerProgress(p.one.T3));
				Assert.AreEqual(0f, TriggerProgress(p.two.T1));
				Assert.AreEqual(0f, TriggerProgress(p.two.T2));
				Assert.AreEqual(0.4f, TriggerProgress(p.two.T3));
				
			}
		}
	}
}
