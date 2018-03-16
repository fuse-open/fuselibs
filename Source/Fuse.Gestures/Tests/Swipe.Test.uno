using Uno;
using Uno.Testing;

using Fuse.Input;
using Fuse.Triggers;
using Fuse.Triggers.Actions;

using FuseTest;

namespace Fuse.Gestures.Test
{
	public class SwipeTest : TestBase
	{
		[Test]
		public void Active()
		{	
			var p = new UX.SwipedTest();
			using (var root = TestRootPanel.CreateWithChild(p, int2(1000,500)))
			{
				//trigger on > 50% swipe
				root.PointerPress( float2(500,200) );
				root.PointerSlide( float2(490,200), float2(390,200), 60 ); //lower than speed threshold
				root.PointerRelease( float2(380,200) ); //must be a bit beyond 100 to deal with delayed capture
				root.StepFrame(5); //stabilize
				
				Assert.AreEqual(1, TriggerProgress(p.SA));
				Assert.AreEqual(1, p.SwipeActive.PerformedCount);
				Assert.AreEqual(1, p.SwipeEither.PerformedCount);
				Assert.AreEqual(0, p.SwipeInactive.PerformedCount);
				
				//swipe back a bit, but not far enough and too slow
				root.PointerPress( float2(500,200) );
				root.PointerSlide( float2(500,200), float2(550,200), 60 );
				root.PointerRelease( float2(550,200) );
				root.StepFrame(5); //stabilize
				
				Assert.AreEqual(1, TriggerProgress(p.SA));
				Assert.AreEqual(1, p.SwipeActive.PerformedCount);
				Assert.AreEqual(1, p.SwipeEither.PerformedCount);
				Assert.AreEqual(0, p.SwipeInactive.PerformedCount);
				
				//swipe a bit, but fast enough to close
				root.PointerSwipe( float2(500,200), float2(550,200), 500 );
				root.StepFrame(5); //stabilize
				
				Assert.AreEqual(0, TriggerProgress(p.SA));
				Assert.AreEqual(1, p.SwipeActive.PerformedCount);
				Assert.AreEqual(2, p.SwipeEither.PerformedCount);
				Assert.AreEqual(1, p.SwipeInactive.PerformedCount);
				
				//swipe to full and release 
				//https://github.com/fusetools/fuselibs-private/issues/1655
				root.PointerSwipe( float2(500,200), float2(200,200), 500 );
				//shouldn't need to stabilize
				
				Assert.AreEqual(1, TriggerProgress(p.SA));
				Assert.AreEqual(2, p.SwipeActive.PerformedCount);
				Assert.AreEqual(3, p.SwipeEither.PerformedCount);
				Assert.AreEqual(1, p.SwipeInactive.PerformedCount);
			}
		}
		
		[Test]
		//ensures the revert of the active swipe gestures happens during Layout Cleanup
		public void SimpleDefer()
		{
			var p = new UX.Swipe.SimpleDefer();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000)))
			{
				root.PointerSwipe( float2(200,300), float2(200,400), 500 );
				root.StepFrame(5); //stabilize
				
				Assert.AreEqual(1, p.D.Normal);
				Assert.AreEqual(1, p.D.Later);
				Assert.AreEqual(0, p.D.Post);
			}
		}
		
		[Test]
		//tests some bound conditions in the swiper for events
		public void Event()
		{
			var p = new UX.Swipe.Event();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000)))
			{
				root.PointerPress( float2(500,500) );
				root.PointerSlide( float2(500,500), float2(500,350), 200 );
				root.IncrementFrame();
				
				Assert.AreEqual(1, TriggerProgress(p.Anim) );
				Assert.AreEqual(0, p.SwipeActive.PerformedCount );
				Assert.AreEqual(0, p.SwipeInactive.PerformedCount );
				root.PointerRelease( float2(500,350) );
				root.PumpDeferred();
				
				Assert.AreEqual(0, TriggerProgress(p.Anim) );
				Assert.AreEqual(1, p.SwipeActive.PerformedCount );
				Assert.AreEqual(0, p.SwipeInactive.PerformedCount );
				Assert.AreEqual(0, p.SwipeCancelled.PerformedCount );
				root.StepFrame(5); //stabilize

				//no events, not far enough to trigger
				root.PointerSwipe( float2(500,500), float2(500,460), 50 ); //speed below threshold
				
				Assert.IsTrue( TriggerProgress(p.Anim) > 0 ); //was partially pulled, will animate back
				Assert.AreEqual(1, p.SwipeActive.PerformedCount );
				Assert.AreEqual(0, p.SwipeInactive.PerformedCount );
				Assert.AreEqual(0, p.SwipeCancelled.PerformedCount );
				
				root.StepFrame(5); //enough to stabilize
				Assert.AreEqual(0, TriggerProgress(p.Anim) );
				Assert.AreEqual(1, p.SwipeCancelled.PerformedCount );
				
				//swipe to end and back
				root.PointerPress( float2(500,500) );
				root.PointerSlide( float2(500,500), float2(500,350), 200 );
				root.PointerSlide( float2(500,350), float2(500,550), 200 );
				root.PointerRelease( float2(500,550) );
				root.StepFrame();
				
				Assert.AreEqual(0, TriggerProgress(p.Anim) );
				Assert.AreEqual(1, p.SwipeActive.PerformedCount );
				Assert.AreEqual(0, p.SwipeInactive.PerformedCount );
				Assert.AreEqual(2, p.SwipeCancelled.PerformedCount );
			}
		}
		
		[Test]
		public void Action()
		{
			var p = new UX.Swipe.Action();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000)))
			{
				Assert.AreEqual(0, TriggerProgress(p.S));
				Assert.AreEqual(0, TriggerProgress(p.W));
				
				p.timeToggle.Pulse();
				root.StepFrame(0.1f);
				var pg = TriggerProgress(p.S);
				Assert.IsTrue( pg > 0 && pg < 1 );
				Assert.AreEqual(0, TriggerProgress(p.W));
				
				root.StepFrame(5);
				Assert.AreEqual(1, TriggerProgress(p.S));
				Assert.AreEqual(1, TriggerProgress(p.W));
				Assert.AreEqual(1, p.SwipeActive.PerformedCount );
				Assert.AreEqual(0, p.SwipeInactive.PerformedCount );
				
				//nohting should change
				p.timeSetOn.Pulse();
				root.PumpDeferred();
				Assert.AreEqual(1, TriggerProgress(p.S));
				Assert.AreEqual(1, TriggerProgress(p.W));
				Assert.AreEqual(1, p.SwipeActive.PerformedCount );
				Assert.AreEqual(0, p.SwipeInactive.PerformedCount );
				
				p.timeBypassOff.Pulse();
				root.PumpDeferred();
				Assert.AreEqual(0,TriggerProgress(p.W));
				Assert.AreEqual(0,TriggerProgress(p.S));
				Assert.AreEqual(1, p.SwipeActive.PerformedCount );
				Assert.AreEqual(0, p.SwipeInactive.PerformedCount ); //was bypass, no trigger
			}
		}
		
		[Test]
		public void ActiveRoot()
		{
			var p = new UX.Swipe.ActiveRoot();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(1,TriggerProgress(p.W));
				Assert.AreEqual(1,TriggerProgress(p.S));
				Assert.AreEqual(0,p.SwipeActive.PerformedCount);
				Assert.AreEqual(0,p.SwipeInactive.PerformedCount);
				
				p.Children.Remove(p.C);
				p.SG.IsActive = false;
				p.Children.Add(p.C);
				root.IncrementFrame();
				
				Assert.AreEqual(0,TriggerProgress(p.W));
				Assert.AreEqual(0,TriggerProgress(p.S));
				Assert.AreEqual(0,p.SwipeActive.PerformedCount);
				Assert.AreEqual(0,p.SwipeInactive.PerformedCount);
			}
		}
		
		[Test]
		//tests a sane result if animation interrupted
		public void Partial()
		{
			var p = new UX.Swipe.Partial();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000)))
			{
				root.PointerSwipe( float2(500,500), float2(600,500), 500 );
				root.StepFrame();
				
				Assert.IsTrue( TriggerProgress(p.S) > 0 );
				Assert.AreEqual(0, TriggerProgress(p.W));
				
				p.SG.IsActive = false;
				root.StepFrame(5);
				
				Assert.AreEqual(0,TriggerProgress(p.S) );
				Assert.AreEqual(0, TriggerProgress(p.W));
				Assert.AreEqual(0,p.SwipeActive.PerformedCount);
				Assert.AreEqual(0,p.SwipeInactive.PerformedCount);
			}
		}
		
		[Test]
		public void Progress()
		{
			var p = new UX.Swipe.Progress();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000)))
			{
				Assert.AreEqual(0, TriggerProgress(p.W1));
				Assert.AreEqual(0, TriggerProgress(p.W5));
				
				var speed = 50f;
				root.PointerPress( float2(500,500) );
				root.PointerSlide( float2(500,500), 
					float2(460 - GestureHardCaptureSignificanceThreshold,500), speed );
				
				//it may start a frame after passing the treshhold
				const float zeroTolerance = 1e-05f;
				var off = 2 * root.StepIncrement * speed / 100/*Length*/ + zeroTolerance;
				Assert.AreEqual(0.4f, TriggerProgress(p.S), off);
				Assert.AreEqual(0, TriggerProgress(p.W1));
				Assert.AreEqual(0, TriggerProgress(p.W5));
				
				root.PointerSlide( 
					float2(460 - GestureHardCaptureSignificanceThreshold,500),
					float2(440 - GestureHardCaptureSignificanceThreshold,500), speed );
					
				Assert.AreEqual(0.6f, TriggerProgress(p.S), off);
				Assert.AreEqual(0, TriggerProgress(p.W1));
				Assert.AreEqual(1, TriggerProgress(p.W5));
				
				//slide a tad bit further to reach end even with "off" delay
				root.PointerSlide( 
					float2(440 - GestureHardCaptureSignificanceThreshold,500),
					float2(400 - GestureHardCaptureSignificanceThreshold - off * 100/*Lentgth*/,500), speed );
					
				Assert.AreEqual(1, TriggerProgress(p.S));
				Assert.AreEqual(1, TriggerProgress(p.W1));
				Assert.AreEqual(1, TriggerProgress(p.W5));
				
				root.PointerRelease(float2(300,500));
				root.PumpDeferred();
				
				Assert.AreEqual(1, TriggerProgress(p.S));
				Assert.AreEqual(1, TriggerProgress(p.W1));
				Assert.AreEqual(1, TriggerProgress(p.W5));
			}
		}
		
		[Test]
		//test InProgress via WhileSwiping
		public void InProgress()
		{
			var p = new UX.Swipe.InProgress();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000)))
			{
				Assert.AreEqual(0, TriggerProgress(p.W));

				//full swipe
				root.PointerPress(float2(500,500));
				root.PointerSlide(float2(500,500), float2(450,500),500); //wrong direction
				Assert.AreEqual(0, TriggerProgress(p.W));
				
				root.PointerSlide(float2(450,500), float2(700,500),500);
				Assert.AreEqual(1, TriggerProgress(p.W));
				
				root.PointerRelease(float2(700,500));
				root.StepFrame();
				Assert.AreEqual(1, TriggerProgress(p.W));

				root.StepFrame(5); //stabilize animation
				Assert.AreEqual(0, TriggerProgress(p.W));
				root.StepFrame();
				
				//abort swipe
				root.PointerPress(float2(500,500));
				root.PointerSlide(float2(500,500), float2(600,500),50); //too slow
				Assert.AreEqual(1, TriggerProgress(p.W));
				
				root.PointerRelease(float2(600,500));
				root.StepFrame();
				Assert.AreEqual(1, TriggerProgress(p.W));
				
				root.StepFrame(5); //stabilize animation
				Assert.AreEqual(0, TriggerProgress(p.W));
			}
		}
		
		[Test]
		public void ScrollView()
		{
			var p = new UX.Swipe.ScrollView();
			using (var root = TestRootPanel.CreateWithChild(p, int2(1000)))
			{
				Assert.IsFalse(p.swipeDown.IsActive);
				Assert.AreEqual(0, TriggerProgress(p.swipeDownAnim));
				Assert.AreEqual(0, p.sv.ScrollPosition.Y );
				
				root.PointerPress(float2(500,100));
				root.PointerSlide(float2(500,100),float2(500,150),500); //fast enough to swipe in
				Assert.IsFalse(p.swipeDown.IsActive);
				Assert.IsTrue( TriggerProgress(p.swipeDownAnim) > 0 );
				Assert.IsTrue( p.sv.ScrollPosition.Y < 0 );
				
				root.PointerRelease(float2(500,150));
				root.StepFrame(5); //stabilize
				Assert.IsTrue(p.swipeDown.IsActive);
				Assert.AreEqual(1, TriggerProgress(p.swipeDownAnim) );
				Assert.AreEqual(0, p.sv.ScrollPosition.Y  ); //snap region
				
				///close it
				root.PointerSwipe( float2(500,200), float2(500,100), 20 ); //slow but well over half-way
				Assert.IsFalse(p.swipeDown.IsActive);
				root.StepFrame(1);
				Assert.AreEqual(0, TriggerProgress(p.swipeDownAnim) );
				Assert.IsTrue( p.sv.ScrollPosition.Y > 50  );
			}
		}
		
		[Test]
		public void Edge()
		{
			var p = new UX.Swipe.Edge();
			using (var root = TestRootPanel.CreateWithChild(p, int2(500,1000)))
			{
				//swipe just within default 100 activation area
				root.PointerSwipe( float2(100,901), float2(100,600), 100 );
				root.StepFrame(5);
				Assert.AreEqual( 1, TriggerProgress(p.SA) );
				
				//swipe away just within revealed panel
				root.PointerSwipe( float2(200,601), float2(200,900), 100 );
				root.StepFrame(5);
				Assert.AreEqual( 0, TriggerProgress(p.SA) );
			}
		}
		
		[Test]
		public void Layers()
		{
			var p = new UX.Swipe.Layers();
			using (var root = TestRootPanel.CreateWithChild(p,int2(500)))
			{
				Assert.AreEqual(false, p.rightSG.IsActive);
 				Assert.AreEqual(false, p.scrollSG.IsActive);
 				Assert.AreEqual(0,p.SV.ScrollPosition.X);
				
				//somehow different swipe speeds made a difference before
				for (int i=1; i <= 5; ++i)
				{
					root.PointerSwipe( float2(490,100), float2(300,100), i * 100 );
					root.StepFrame(5);
					Assert.AreEqual(1,TriggerProgress(p.rightAnim));
					Assert.AreEqual(true, p.rightSG.IsActive);
					Assert.AreEqual(false, p.scrollSG.IsActive);
					Assert.AreEqual(0,p.SV.ScrollPosition.X);
					
					root.PointerSwipe( float2(305,100), float2(490,100), i * 100 );
					root.StepFrame(5);
					Assert.AreEqual(0,TriggerProgress(p.rightAnim));
					Assert.AreEqual(false, p.rightSG.IsActive);
					Assert.AreEqual(false, p.scrollSG.IsActive);
					Assert.AreEqual(0,p.SV.ScrollPosition.X);
				}
			}
		}
		
		[Test]
		//a white-box test of the gesture significance values
		public void GestureSignificance()
		{
			var p = new UX.Swipe.GestureSignificance();
			using (var root = TestRootPanel.CreateWithChild(p,int2(500)))
			{
				var g = p.SG.TestSwiper as IGesture;
				Assert.AreEqual(0, g.Priority.Significance);
				
				root.PointerPress( float2(100,450));
				root.PointerSlide( float2(100,450), float2(100,448), 100 );
				Assert.AreEqual(2, g.Priority.Significance);
				root.PointerSlide( float2(100,448), float2(100,445), 100 );
				Assert.AreEqual(5, g.Priority.Significance);
				root.PointerRelease( float2(100,445) );
				
				p.SG.IsActive = true;
				root.StepFrame(5); //stabilize
				root.PointerPress( float2(100,305) );
				root.PointerSlide( float2(100,305), float2(100,310), 100 );
				Assert.AreEqual(5, g.Priority.Significance);
				root.PointerRelease( float2(100,310) );
			}
		}
		
		[Test]
		public void GestureSignificance2()
		{
			var p = new UX.Swipe.GestureSignificance2();
			using (var root = TestRootPanel.CreateWithChild(p,int2(500)))
			{
				var g = p.SG.TestSwiper as IGesture;
				var g2 = p.SU.TestSwiper as IGesture;
				Assert.AreEqual(0, g.Priority.Significance);
				Assert.AreEqual(0, g2.Priority.Significance);
				
				root.PointerPress( float2(100,450));
				root.PointerSlide( float2(100,450), float2(100,448), 100 );
				Assert.AreEqual(2, g.Priority.Significance);
				Assert.AreEqual(2, g2.Priority.Significance);
				Assert.IsTrue(g.Priority.Adjustment > g2.Priority.Adjustment);
				
				root.PointerSlide( float2(100,448), float2(100,445), 100 );
				Assert.AreEqual(5, g.Priority.Significance);
				Assert.AreEqual(5, g2.Priority.Significance);
			}
		}
		
		[Test]
		public void Auto()
		{
			var p = new UX.Swipe.Auto();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000)))
			{	
				root.PointerPress(float2(500,100));
				root.PointerSlideRel(float2(-150,0));
				Assert.AreEqual(1, p.CLeft.PerformedCount );
				root.PointerSlideRel(float2(-0,-105));
				Assert.AreEqual(1, p.CUp.PerformedCount );
				root.PointerSlideRel(float2(-105,0));
				Assert.AreEqual(2, p.CLeft.PerformedCount );
				root.PointerSlideRel(float2(-300,0)); //really far into left shouldn't matter...
				root.PointerSlideRel(float2(0,-105)); //...still triggers up
				Assert.AreEqual(2, p.CUp.PerformedCount );
				root.PointerRelease();
				
				root.PointerPress(float2(500));
				root.PointerSlideRel(float2(-50,0)); //enough to select Left
				root.PointerSlideRel(float2(-150,0)); //would be up,but excluded
				Assert.AreEqual(2, p.CUp.PerformedCount );
			}
		}
		
		[Test]
		public void GesturePriority()
		{
			var p = new UX.Swipe.GesturePriority();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000)))
			{
				//works on left, since no competition
				root.PointerSwipe( float2(250,500), float2(250,300), 100 );
				Assert.AreEqual(1, p.CUp.PerformedCount );
				Assert.AreEqual(0, p.SV.ScrollPosition.Y);
				
				root.StepFrame(5);
				
				//on right the scroller has higher priority
				root.PointerSwipe( float2(750,500), float2(750,300), 100 );
				Assert.AreEqual(1, p.CUp.PerformedCount );
				Assert.IsTrue(p.SV.ScrollPosition.Y > 50); //exact value isn't relevant
				
				root.StepFrame(5);
				var oldPos = p.SV.ScrollPosition.Y;
				
				//down has priority on both sides
				root.PointerSwipe( float2(250,500), float2(250,700), 100 );
				Assert.AreEqual(1, p.CDown.PerformedCount );
				Assert.AreEqual(oldPos, p.SV.ScrollPosition.Y);
				
				root.StepFrame(5);
				
				root.PointerSwipe( float2(750,500), float2(750,700), 100 );
				Assert.AreEqual(2, p.CDown.PerformedCount );
				Assert.AreEqual(oldPos, p.SV.ScrollPosition.Y);
			}
		}
		
		[Test]
		public void Threshold()
		{
			var p = new UX.Swipe.Threshold();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000)))
			{
				SlowSlide( root, p.Anim, float2(500,200), float2(0,1), 0.7f );
				Assert.AreEqual( 0, p.Anim.Progress );
				Assert.AreEqual( 0, p.SwipeActive.PerformedCount );
				Assert.AreEqual( 0, p.SwipeInactive.PerformedCount );
				Assert.AreEqual( 1, p.SwipeCancelled.PerformedCount );
				
				SlowSlide( root, p.Anim, float2(500,200), float2(0,1), 0.8f );
				Assert.AreEqual( 1, p.Anim.Progress );
				Assert.AreEqual( 1, p.SwipeActive.PerformedCount );
				Assert.AreEqual( 0, p.SwipeInactive.PerformedCount );
				Assert.AreEqual( 1, p.SwipeCancelled.PerformedCount );
				
				SlowSlide( root, p.Anim, float2(500,200), float2(0,1), -0.35f );
				Assert.AreEqual( 1, p.Anim.Progress );
				Assert.AreEqual( 1, p.SwipeActive.PerformedCount );
				Assert.AreEqual( 0, p.SwipeInactive.PerformedCount );
				Assert.AreEqual( 2, p.SwipeCancelled.PerformedCount );
				
				SlowSlide( root, p.Anim, float2(500,200), float2(0,1), -0.45f );
				Assert.AreEqual( 0, p.Anim.Progress );
				Assert.AreEqual( 1, p.SwipeActive.PerformedCount );
				Assert.AreEqual( 1, p.SwipeInactive.PerformedCount );
				Assert.AreEqual( 2, p.SwipeCancelled.PerformedCount );
			}
		}
		
		/* slides a relative amount along the gesture accounting for the capture delay */
		void SlowSlide( TestRootPanel root, SwipingAnimation anim, float2 from, float2 dir, float rel )
		{
			var length = anim.Source.Length;
			
			root.PointerPress( from );
			
			//slide a bit, then capture progress to account for capture threshold
			var bit = from + dir * 10 * Math.Sign(rel);
			root.PointerSlide( from, bit, 60 ); //lower than speed threshold
			
			var b = (float)anim.Progress;
			var relOff = rel > 0 ? (rel-b) : (rel-(1-b));
			var end = bit + dir * relOff * length;
			root.PointerSlide( bit, end, 60);
			
			root.PointerRelease( end );
			root.StepFrame(5);
		}
	}
	
	class DeferAction : TriggerAction
	{
		Trigger SA;
		public double Normal=-1, Later=-1, Post=-1;
		protected override void Perform(Node target)
		{
			SA = target.FindByType<UX.Swipe.SimpleDefer>().SA;
			Normal = SA.Progress;
			UpdateManager.AddDeferredAction(CheckLater, LayoutPriority.Later);
			UpdateManager.AddDeferredAction(CheckPost, LayoutPriority.Post);
		}
		
		void CheckLater()
		{
			Later = SA.Progress;
		}
		
		void CheckPost()
		{
			Post = SA.Progress;
		}
	}
}
