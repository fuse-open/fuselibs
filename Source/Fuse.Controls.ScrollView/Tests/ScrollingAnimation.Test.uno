using Uno;
using Uno.Testing;

using FuseTest;

using Fuse.Elements;

namespace Fuse.Controls.ScrollViewTest
{
	public class ScrollingAnimationTest : TestBase
	{
		[Test]
		public void ScrollingAnimation()
		{
			var sv = new UX.ScrollingAnimation.Multi();
			using (var root = TestRootPanel.CreateWithChild(sv,int2(500,1000)))
			{
				Assert.AreEqual(float2(0,1000),sv.MaxScroll);
				Assert.AreEqual(float2(0,0),sv.MinScroll);
				
				Assert.AreEqual(0, TriggerProgress(sv.S1));
				Assert.AreEqual(0, TriggerProgress(sv.S2));
				Assert.AreEqual(0, TriggerProgress(sv.Min));
				Assert.AreEqual(0, TriggerProgress(sv.Max));
				
				sv.ScrollPosition = float2(0,500);
				root.IncrementFrame(0.1f);
				Assert.AreEqual(0.5f, TriggerProgress(sv.S1));
				Assert.AreEqual(0.25f, TriggerProgress(sv.S2));
				
				sv.ScrollPosition = float2(0,1000);
				root.IncrementFrame(0.1f);
				Assert.AreEqual(1.0f, TriggerProgress(sv.S1));
				Assert.AreEqual(1.0f, TriggerProgress(sv.S2));
				
				//assuming overflowExtent=150
				sv.ScrollPosition = float2(0,-75);
				//careful here, these values may only be stable for 1-frame if out-of-range due to the
				//scroller's gesture animation
				root.IncrementFrame(0.1f);
				Assert.AreEqual(0,TriggerProgress(sv.S1));
				Assert.AreEqual(75f/150f,TriggerProgress(sv.Min));
				Assert.AreEqual(0,TriggerProgress(sv.Max));
				
				sv.ScrollPosition = float2(0,1025);
				root.IncrementFrame(0.1f);
				Assert.AreEqual(1,TriggerProgress(sv.S1));
				Assert.AreEqual(0,TriggerProgress(sv.Min));
				Assert.AreEqual(25f/150f,TriggerProgress(sv.Max));
			}
		}
		
		/**
			Ensures that ScrollPositionChanged message when the relative position changes, even if
			the absolute scroll position does not.
		*/
		[Test]
		public void ScrollingAnimationRelative()
		{
			var sv = new UX.ScrollingAnimation.Relative();
			using (var root = TestRootPanel.CreateWithChild(sv,int2(100,50)))
			{
				Assert.AreEqual(400,sv.MaxScroll.X);
				Assert.AreEqual(0, TriggerProgress(sv.S1));
				
				sv.ScrollPosition = float2(100,0);
				root.StepFrame(5);
				Assert.AreEqual(0.25f,TriggerProgress(sv.S1));
				
				//remove item, absolute ScrollPosition does not change, but animator should update
				sv.TheRect.Visibility = Visibility.Collapsed;
				root.StepFrame(5);
				Assert.AreEqual(1/3.0f,TriggerProgress(sv.S1));
				
				sv.TheRect.Visibility = Visibility.Visible;
				root.StepFrame(5);
				Assert.AreEqual(0.25f,TriggerProgress(sv.S1));
			}
		}

		/**
			Ensure that the ScrollingAnimation's progress is updated if From or To
			changes at runtime
		*/
		[Test]
		public void ScrollingAnimationFromTo()
		{
			var sv = new UX.ScrollingAnimation.FromTo();
			using (var root = TestRootPanel.CreateWithChild(sv, int2(100,50)))
			{
				Assert.AreEqual(0.0f, TriggerProgress(sv.S1));

				sv.ScrollPosition = float2(0,200);
				root.StepFrame(5);
				Assert.AreEqual(1.0f, TriggerProgress(sv.S1));

				sv.S1.From = 100.0f;
				sv.S1.To = 300.0f;
				Assert.AreEqual(0.5f, TriggerProgress(sv.S1));

				sv.S1.From = 200.0f;
				Assert.AreEqual(0.0f, TriggerProgress(sv.S1));
			}
		}
	}
}
