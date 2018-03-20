using Uno;
using Uno.UX;
using Uno.Testing;

using FuseTest;

using Fuse.Elements;

namespace Fuse.Controls.ScrollViewTest
{
	public class ScrollViewTest : TestBase
	{
		[Test]
		public void AllowedScrollDirections()
		{
			var s = new ScrollView();
			Assert.AreEqual(ScrollDirections.Vertical, s.AllowedScrollDirections);
			s.AllowedScrollDirections = ScrollDirections.Both;
			Assert.AreEqual(ScrollDirections.Both, s.AllowedScrollDirections);
		}

		[Test]
		public void ScrollPosition_1()
		{
			var s = new ScrollView();
			Assert.AreEqual(float2(0), s.ScrollPosition);
			s.ScrollPosition = float2 (100,100);
			Assert.AreEqual(float2(0,100), s.ScrollPosition);
		}

		[Test]
		public void ScrollPosition_2()
		{
			var s = new ScrollView();
			s.AllowedScrollDirections = ScrollDirections.Both;
			Assert.AreEqual(float2(0), s.ScrollPosition);
			s.ScrollPosition = float2(100, 100);
			Assert.AreEqual(float2(100), s.ScrollPosition);
		}

		[Test]
		public void MaxStyleApply()
		{
			var p = new UX.ScrollViewMaxStyleApply();
			using (var root = TestRootPanel.CreateWithChild(p, int2(200, 200)))
			{
				Assert.AreEqual(float2(200,1000),p.sp1.ActualSize);
				Assert.AreEqual(float2(1000,200),p.sp2.ActualSize);
				Assert.AreEqual(float2(1000,1000),p.sp3.ActualSize);
			}
		}
		
		[Test]
		public void BringIntoViewTest()
		{
			var parent = new UX.ScrollView.BringIntoView();

			using (var root = TestRootPanel.CreateWithChild(parent, int2(50, 400)))
			{
				var scrollViewBehavior = parent.TestScroller;

				root.Layout(int2(50, 400));

				Assert.AreEqual(float2 (0, 0), scrollViewBehavior.TestTargetDestination);

				parent.P2.BringIntoView();
				//pending is performed after layout
				root.IncrementFrame(0.1f);
				//The elements are centered in the ScrollView
				Assert.AreEqual(float2(0, 250), scrollViewBehavior.TestTargetDestination);

				parent.P3.BringIntoView();
				root.IncrementFrame(0.1f);
				//maxed-out position
				Assert.AreEqual(float2(0, 500), scrollViewBehavior.TestTargetDestination);

				parent.S1.Children.Add(parent.P4);
				parent.P4.BringIntoView();
				root.IncrementFrame(0.1f);
				//also maxed-out
				Assert.AreEqual(float2(0, 800), scrollViewBehavior.TestTargetDestination);

				parent.S1.Children.Remove(parent.P2);
				parent.P3.BringIntoView();
				root.IncrementFrame(0.1f);
				Assert.AreEqual(float2(0, 250), scrollViewBehavior.TestTargetDestination);

				parent.P1.BringIntoView();
				root.IncrementFrame(0.1f);
				Assert.AreEqual(float2(0, 0), scrollViewBehavior.TestTargetDestination);

				//ensure BringIntoView happens post layout
				parent.P1.Height = 500;
				parent.P3.BringIntoView();
				root.IncrementFrame(0.1f);
				Assert.AreEqual(float2(0, 450), scrollViewBehavior.TestTargetDestination);
			}
		}

		[Test]
		public void Extents()
		{
			var sv = new UX.ScrollViewExtent();
			using (var root = TestRootPanel.CreateWithChild(sv, int2(500, 1000)))
			{
				Assert.AreEqual(float2(0,1200),sv.MaxScroll);
				Assert.AreEqual(float2(0,0),sv.MinScroll);
				Assert.AreEqual(float2(0,0),sv.ScrollPosition);
				Assert.AreEqual(float2(0,1350),sv.MaxOverflow);
				Assert.AreEqual(float2(0,-150),sv.MinOverflow);
			}
		}
			

		/**
			Ensures that a scroller doesn't loose track of the desired target and bounds
			when an item's visibility is collapsed/restored.
		*/
		[Test]
		public void ScrollIssue1595()
		{
			//https://github.com/fusetools/fuselibs-private/issues/1595
			var p = new UX.ScrollIssue1595();
			using (var root = TestRootPanel.CreateWithChild(p, int2(200, 500)))
			{
				p.P1.Visibility = Visibility.Visible;
				p.P1.BringIntoView();
				root.IncrementFrame(0.01f);
				Assert.AreEqual(300, p.SV.TestScroller.TestTargetDestination.X);

				root.IncrementFrame(0.01f);

				p.P1.Visibility = Visibility.Collapsed;
				root.IncrementFrame(0.01f);
				//should still be in destination move mode, but with a new clipped destination
				Assert.AreEqual(200, p.SV.TestScroller.TestTargetDestination.X);

				root.IncrementFrame(0.01f);

				//back to the hidden item
				p.P1.Visibility = Visibility.Visible;
				p.P1.BringIntoView();
				root.IncrementFrame(0.01f);
				Assert.AreEqual(300, p.SV.TestScroller.TestTargetDestination.X);
				//allow to stabilize
				root.StepFrame(5);
				Assert.AreEqual(300, p.SV.ScrollPosition.X);

				//hide again
				p.P1.Visibility = Visibility.Collapsed;
				root.IncrementFrame(0.01f);
				Assert.AreEqual(200, p.SV.TestScroller.TestTargetDestination.X);
			}
		}
		
		[Test]
		public void ScrollViewAlignment()
		{
			var sv = new UX.ScrollViewAlignment();
			using (var root = TestRootPanel.CreateWithChild( sv, int2(200,400) ))
			{
				Assert.AreEqual( float2(0,-600), sv.SV1.MinScroll );
				Assert.AreEqual( float2(0,0), sv.SV1.MaxScroll );
				Assert.AreEqual( float2(0,-600), sv.C1.ActualPosition );

				Assert.AreEqual( float2(0,0), sv.SV2.MinScroll );
				Assert.AreEqual( float2(0,600), sv.SV2.MaxScroll );
				Assert.AreEqual( float2(0,0), sv.C2.ActualPosition );

				Assert.AreEqual( float2(0,-300), sv.SV3.MinScroll );
				Assert.AreEqual( float2(0,300), sv.SV3.MaxScroll );
				Assert.AreEqual( float2(0,-300), sv.C3.ActualPosition );

				Assert.AreEqual( float2(-620,-760), sv.SV4.MinScroll );
				Assert.AreEqual( float2(620,760), sv.SV4.MaxScroll );
				Assert.AreEqual( float2(-620,-760), sv.C4.ActualPosition );
				Assert.AreEqual( float2(1440,1920), sv.C4.ActualSize );

				Assert.AreEqual( float2(-1248.8f,0), sv.SV5.MinScroll );
				Assert.AreEqual( float2(0,0), sv.SV5.MaxScroll );
				Assert.AreEqual( float2(-1248.8f,0), sv.C5.ActualPosition );
				Assert.AreEqual( float2(1448.8f,400), sv.C5.ActualSize );

				Assert.AreEqual( float2(0,0), sv.SV6.MinScroll );
				Assert.AreEqual( float2(0,0), sv.SV6.MaxScroll );
				Assert.AreEqual( float2(0,0), sv.C6.ActualPosition );
				Assert.AreEqual( float2(200,400), sv.C6.ActualSize );

				Assert.AreEqual( float2(0,0), sv.SV7.MinScroll );
				Assert.AreEqual( float2(0,0), sv.SV7.MaxScroll );
				Assert.AreEqual( float2(0,0), sv.C7.ActualPosition );
				Assert.AreEqual( float2(200,400), sv.C7.ActualSize );

				Assert.AreEqual( float2(0,0), sv.SV8.MinScroll );
				Assert.AreEqual( float2(0,0), sv.SV8.MaxScroll );
				Assert.AreEqual( float2(0,0), sv.C8.ActualPosition );
				Assert.AreEqual( float2(200,100), sv.C8.ActualSize );

				Assert.AreEqual( float2(0,0), sv.SV9.MinScroll );
				Assert.AreEqual( float2(0,0), sv.SV9.MaxScroll );
				Assert.AreEqual( float2(50,0), sv.C9.ActualPosition );
				Assert.AreEqual( float2(100,400), sv.C9.ActualSize );

				Assert.AreEqual( float2(0,0), sv.SV10.MinScroll );
				Assert.AreEqual( float2(0,0), sv.SV10.MaxScroll );
				Assert.AreEqual( float2(50,175), sv.C10.ActualPosition );
				Assert.AreEqual( float2(100,50), sv.C10.ActualSize );

				Assert.AreEqual( float2(0,0), sv.SV11.MinScroll );
				Assert.AreEqual( float2(0,0), sv.SV11.MaxScroll );
				Assert.AreEqual( float2(40,165), sv.C11.ActualPosition );
				Assert.AreEqual( float2(120,70), sv.C11.ActualSize );

				Assert.AreEqual( float2(0,0), sv.SV12.MinScroll );
				Assert.AreEqual( float2(0,0), sv.SV12.MaxScroll );
				Assert.AreEqual( float2(30,155), sv.C12.ActualPosition );
				Assert.AreEqual( float2(140,90), sv.C12.ActualSize );
			}
		}
		
		[Test]
		public void UserScroll()
		{
			var sv = new UX.UserScroll();
			using (var root = TestRootPanel.CreateWithChild( sv, int2(1000) ))
			{
				Assert.AreEqual(0,sv.S.ScrollPosition.Y);

				root.PointerSwipe(float2(100,500), float2(100,400),100);
				//the actual scroll position depends on physics/delayed-start, it's of no interest here
				root.StepFrame(5); //let animation stabilize
				var pos = sv.S.ScrollPosition.Y;
				Assert.IsTrue(pos > 80);

				sv.S.UserScroll = false;
				root.PointerSwipe(float2(100,500), float2(100,400),100);
				Assert.AreEqual(pos, sv.S.ScrollPosition.Y);
			}
		}
		
		[Test]
		public void UserInteraction()
		{
			var sv = new UX.UserScroll();
			using (var root = TestRootPanel.CreateWithChild(sv,int2(1000)))
			{
				Assert.AreEqual(0, sv.S.ScrollPosition.Y);

				float speed = 100;
				root.PointerPress(float2(100,500));
				root.PointerSlide(float2(100,500), float2(100,300), speed);
				//adjust for delayed gesture and accuracy of sliding steps
				const float zeroTolerance = 1e-05f;
				Assert.AreEqual(200 - GestureHardCaptureSignificanceThreshold, 
					sv.S.ScrollPosition.Y, 2 * root.StepIncrement * speed + zeroTolerance);
			}
		}
		
		[Test]
		public void LayoutChangeBottom()
		{
			var sv = new UX.LayoutChange();
			using (var root = TestRootPanel.CreateWithChild( sv, int2(150) ))
			{
				Assert.AreEqual( 0, sv.S.ScrollPosition.Y );

				sv.T.Children.Insert(0,sv.P1);
				root.IncrementFrame();
				Assert.AreEqual( 0, sv.S.ScrollPosition.Y );

				sv.T.Children.Add(sv.P3);
				root.IncrementFrame();
				Assert.AreEqual( -100, sv.S.ScrollPosition.Y );
			}
		}
		
		[Test]
		public void LayoutChangeTop()
		{
			var sv = new UX.LayoutChange();
			sv.T.Alignment = Alignment.Top;
			using (var root = TestRootPanel.CreateWithChild( sv, int2(150) ))
			{
				Assert.AreEqual( 0, sv.S.ScrollPosition.Y );
				root.StepFrame(5); //alignment chagne above may cause animation

				sv.T.Children.Insert(0,sv.P1);
				root.StepFrame(5);
				//50 is as far as it should go to be in range, see:
				//https://github.com/fusetools/fuselibs-private/issues/2891
				//tolerance needed due to tolerance check in `ScrollView.SetScrolPositionImpl`
				Assert.AreEqual( 50, sv.S.ScrollPosition.Y, 1e-3 );

				sv.T.Children.Add(sv.P3);
				root.IncrementFrame();
				Assert.AreEqual( 50, sv.S.ScrollPosition.Y, 1e-3 );
			}
		}
		
		[Test]
		public void ScrollPositionChanged()
		{
			var s= new UX.ScrollPositionChanged();
			using (var root = TestRootPanel.CreateWithChild(s, int2(100,1000)))
			{
				root.StepFrameJS();
				root.StepFrameJS(); //first event isn't sent until this frame
				Assert.AreEqual( "0,0 50,0", s.T.Value );

				s.SV.ScrollPosition = float2(0,100);
				root.StepFrameJS();
				Assert.AreEqual( "0,10000 50,1", s.T.Value );

				s.SV.ScrollPosition = float2(0,800);
				root.StepFrameJS();
				Assert.AreEqual( "0,80000 50,8", s.T.Value );
			}
		}
		
		[Test]
		//UserMode must be maintained regardless of what happens to the scroller
		public void UserMode()
		{
			var s = new UX.UserMode();
			using (var root = TestRootPanel.CreateWithChild(s,int2(1000)))
			{
				float speed = 100;
				root.PointerPress(float2(100,500));
				root.PointerSlide(float2(100,500), float2(100,550), speed);
				
				s.SV.Height = new Size(999,Unit.Points); //forces layout reevaluation
				//without the fix this would switch to Destination mode and start scrolling automatically
				root.StepFrame(1);
				root.PointerSlide(float2(100,550), float2(100,580), speed);
				
				s.P.Height = new Size(100,Unit.Points); //force content layout and size change
				root.StepFrame(1);
				root.PointerSlide(float2(100,580), float2(100,600), speed);
				
				//adjust for delayed gesture and accuracy of sliding steps
				// 2*StepIncrement since it's allowed to delay one frame/event now
				const float zeroTolerance = 1e-05f;
				Assert.AreEqual(-100 + GestureHardCaptureSignificanceThreshold, 
					s.SV.ScrollPosition.Y, 2*root.StepIncrement * speed + zeroTolerance);

				Assert.AreEqual( 100 * (-s.SV.ScrollPosition.Y / s.SM.OverflowExtent.Y), s.SAP.Height.Value );
				
				//let it snap now
				root.PointerRelease(float2(100,600));
				root.StepFrame(5);
				Assert.AreEqual(0, s.SV.ScrollPosition.Y );
				Assert.AreEqual(0, s.SAP.Height.Value);
			}
		}
		
		[Test]
		public void GesturePriority()
		{
			var sv = new UX.GesturePriority();
			using (var root = TestRootPanel.CreateWithChild( sv, int2(1000) ))
			{
				Assert.AreEqual(0,sv.S.ScrollPosition.Y);
			
				root.PointerSwipe(float2(100,500), float2(100,400),100);
				Assert.AreEqual( 0, sv.S.ScrollPosition.Y); //SwipeGesture wins out
				root.StepFrame(5); //stabilize

				//make ScrollView win now
				sv.S.GesturePriority = Fuse.Input.GesturePriority.Highest;
				//the actual scroll position depends on physics/delayed-start, it's of no interest here
				root.PointerSwipe(float2(100,500), float2(100,400),100);
				Assert.IsTrue(sv.S.ScrollPosition.Y > 80);
			}
		}
	}
}
