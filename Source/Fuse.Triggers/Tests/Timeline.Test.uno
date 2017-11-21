using Uno;
using Uno.Testing;

using FuseTest;

namespace Fuse.Triggers.Test
{
	/**
		This serves also as a test for the animation system, as how the Timeline works is
		inseparable from that.
	*/
	public class TimelineTest : TestBase
	{
		const float _zeroTolerance = 1e-05f;

		[Test]
		public void Pulse()
		{	
			var p = new UX.TimelinePulse();
			using (var root = TestRootPanel.CreateWithChild(p, int2(100)))
			{
				p.T1.Pulse();
				//the first frame is expected to animate for the interval time
				root.IncrementFrame(0.1f);
				Assert.AreEqual(0.1, TriggerProgress(p.T1));

				//then revert to stepping
				root.StepFrame(0.9f);
				Assert.AreEqual(1, TriggerProgress(p.T1));

				//the pulse turnaround could take 1 frame, it's uncertain if this an issue.
				var tolerance = root.StepIncrement + _zeroTolerance;
				root.StepFrame(0.1f);
				Assert.AreEqual(0.9f, TriggerProgress(p.T1), tolerance);

				root.StepFrame(0.9f);
				Assert.AreEqual(0f, TriggerProgress(p.T1), tolerance);

				//one final frame to catchup at most
				root.IncrementFrame();
				Assert.AreEqual(0f, TriggerProgress(p.T1));
			}
		}
		
		[Test]
		public void SeekPlay()
		{	
			var p = new UX.TimelinePulse();
			using (var root = TestRootPanel.CreateWithChild(p, int2(100)))
			{
				var play = p.T1;

				//seek to target
				play.Progress = 0.2f;
				root.IncrementFrame();
				Assert.AreEqual(0.2, TriggerProgress(p.T1));
				//should be stopped there
				root.IncrementFrame();
				Assert.AreEqual(0.2, TriggerProgress(p.T1));

				//play to new target
				play.TimelinePlayTo(0.8f);
				root.StepFrame(0.6f);
				Assert.AreEqual(0.8f, TriggerProgress(p.T1));
				//should be stopped there
				root.StepFrame(0.2f);
				Assert.AreEqual(0.8f, TriggerProgress(p.T1));

				//pause in middle (pause does not reset target progress)
				play.TimelinePlayTo(1);
				root.StepFrame(0.1f);
				Assert.AreEqual(0.9f, TriggerProgress(p.T1));

				play.Pause();
				root.StepFrame(0.1f);
				Assert.AreEqual(0.9f, TriggerProgress(p.T1));

				play.Resume();
				root.StepFrame(0.1f);
				Assert.AreEqual(1.0f, TriggerProgress(p.T1));

				//stop in middle (stop resets target progress)
				play.Progress = 0;
				play.TimelinePlayTo(1);
				root.StepFrame(0.3f);
				Assert.AreEqual(0.3f, TriggerProgress(p.T1));

				play.Stop();
				root.StepFrame(0.1f);
				Assert.AreEqual(0.3f, TriggerProgress(p.T1));

				play.Resume();
				root.StepFrame(0.1f);
				Assert.AreEqual(0.3f, TriggerProgress(p.T1)); //stopped reset target
			}
		}
		
		[Test]
		public void PulseForward()
		{	
			var p = new UX.TimelinePulse();
			using (var root = TestRootPanel.CreateWithChild(p, int2(100)))
			{
				p.T1.PulseForward();
				root.StepFrame(1f);
				Assert.AreEqual(1, TriggerProgress(p.T1));

				//return to 0
				root.IncrementFrame();
				Assert.AreEqual(0, TriggerProgress(p.T1));

				//and be stopped there
				root.IncrementFrame();
				Assert.AreEqual(0, TriggerProgress(p.T1));
			}
		}
		
		[Test]
		public void PulseBackward()
		{	
			var p = new UX.TimelinePulse();
			using (var root = TestRootPanel.CreateWithChild(p, int2(100)))
			{
				p.T1.PulseBackward();
				root.StepFrame(0.1f);
				Assert.AreEqual(0.9f, TriggerProgress(p.T1));

				root.StepFrame(0.8f);
				Assert.AreEqual(0.1f, TriggerProgress(p.T1));

				root.StepFrame(0.2f); //overstep, stops at 0
				Assert.AreEqual(0f, TriggerProgress(p.T1));
			}
		}
		
		[Test]
		public void WrapPlay()
		{	
			var p = new UX.TimelineWrap();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				//the timeline may animate the first frame it is rooted
				var bp = TriggerProgress(p.T1);
				Assert.AreEqual(0f, TriggerProgress(p.T1), root.StepIncrement + _zeroTolerance);
				Assert.AreEqual(1f, TriggerProgress(p.T2), root.StepIncrement + _zeroTolerance);
				
				//should just start playing with wrap mode (as TargetProgress defaults to 1)
				root.StepFrame(0.1f);
				Assert.AreEqual(bp + 0.1f, TriggerProgress(p.T1));
				Assert.AreEqual(1 - (bp + 0.1f), TriggerProgress(p.T2));
				
				//pause & resume shouldn't change anything
				p.T1.Pause();
				p.T2.Pause();
				p.T1.Resume();
				p.T2.Resume();
				
				root.StepFrame(0.8f);
				Assert.AreEqual(bp + 0.9f, TriggerProgress(p.T1));
				Assert.AreEqual(1 - (bp + 0.9f), TriggerProgress(p.T2));
				
				//this is not a frame-synced, the looping is nonetheless expected to be precise on full elapsed time
				root.StepFrame(0.2f);
				Assert.AreEqual(bp + 0.1f, TriggerProgress(p.T1));
				Assert.AreEqual(1 - (bp + 0.1f), TriggerProgress(p.T2));
				root.StepFrame(1.117f);
				Assert.AreEqual(bp + 0.217f, TriggerProgress(p.T1));
				Assert.AreEqual(1 - (bp + 0.217f), TriggerProgress(p.T2));
				
				//loop a few more times with offset to ensure continued accuracy
				var offset = 0.217f;
				for (int i=0; i<3; ++i)
				{
					root.StepFrame(0.5f);
					Assert.AreEqual(bp + offset + 0.5f, TriggerProgress(p.T1));
					Assert.AreEqual(1 - (bp + offset +0.5f), TriggerProgress(p.T2));
					
					root.StepFrame(0.6f);
					offset += 0.1f;
					Assert.AreEqual(bp + offset, TriggerProgress(p.T1));
					Assert.AreEqual(1 - (bp + offset), TriggerProgress(p.T2));
				}
			}
		}
		
		[Test]
		public void WrapAction()
		{
			var p = new UX.Timeline.WrapAction();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				//the timeline may animate the first frame it is rooted
				var bp = TriggerProgress(p.T1);
				root.StepFrame( (float)(0.5f - bp) ); //duration is 1, so this works
				Assert.AreEqual( 1, p.C10.PerformedCount );
				Assert.AreEqual( 0, p.C11.PerformedCount );
				Assert.AreEqual( 0, p.C20.PerformedCount );
				Assert.AreEqual( 1, p.C21.PerformedCount );
				Assert.AreEqual( 1, p.B10.PerformedCount );
				Assert.AreEqual( 0, p.B11.PerformedCount );
				Assert.AreEqual( 0, p.B20.PerformedCount );
				Assert.AreEqual( 1, p.B21.PerformedCount );
				
				root.StepFrame(0.45f);
				root.IncrementFrame(0.1f); //the increment forces a big gap over the wrapping ends
				Assert.AreEqual( 2, p.C10.PerformedCount );
				Assert.AreEqual( 1, p.C11.PerformedCount );
				Assert.AreEqual( 1, p.C20.PerformedCount );
				Assert.AreEqual( 2, p.C21.PerformedCount );
				Assert.AreEqual( 2, p.B10.PerformedCount );
				Assert.AreEqual( 1, p.B11.PerformedCount );
				Assert.AreEqual( 1, p.B20.PerformedCount );
				Assert.AreEqual( 2, p.B21.PerformedCount );
				
				//standard stepping a few more times
				for (int i=1; i < 4; ++i)
				{
					root.StepFrame(1);
					Assert.AreEqual( 2+i, p.C10.PerformedCount );
					Assert.AreEqual( 1+i, p.C11.PerformedCount );
					Assert.AreEqual( 1+i, p.C20.PerformedCount );
					Assert.AreEqual( 2+i, p.C21.PerformedCount );
					Assert.AreEqual( 2+i, p.B10.PerformedCount );
					Assert.AreEqual( 1+i, p.B11.PerformedCount );
					Assert.AreEqual( 1+i, p.B20.PerformedCount );
					Assert.AreEqual( 2+i, p.B21.PerformedCount );
				}
			}
		}
		
		[Test]
		public void WrapActionIssue3724()
		{
			var p = new UX.Timeline.WrapActionIssue3724();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(false, p.WTA.Value);
				Assert.AreEqual(0,p.C1.PerformedCount);
				Assert.AreEqual(0,p.C2.PerformedCount);
				
				root.StepFrame(0.1f); //offset to avoid exactness
				int c1 = 0;
				int c2 = 0;
				for (int i=0; i < 10; ++i)
				{
					root.StepFrame(1.0f); //@1.1
					c1++;
					Assert.AreEqual(true, p.WTA.Value);
					Assert.AreEqual(c1,p.C1.PerformedCount);
					Assert.AreEqual(c2,p.C2.PerformedCount);
					
					root.StepFrame(1.0f); //@2.1 / 0.1
					c2++;
					Assert.AreEqual(false, p.WTA.Value);
					Assert.AreEqual(c1,p.C1.PerformedCount);
					Assert.AreEqual(c2,p.C2.PerformedCount);
					
					root.StepFrame(1.01f); //@3.1 / 1.1
					c1++;
					Assert.AreEqual(true, p.WTA.Value);
					Assert.AreEqual(c1,p.C1.PerformedCount);
					Assert.AreEqual(c2,p.C2.PerformedCount);
					
					root.StepFrame(1.01f); //@4.1 / 0.1
					c2++;
					Assert.AreEqual(false, p.WTA.Value);
					Assert.AreEqual(c1,p.C1.PerformedCount);
					Assert.AreEqual(c2,p.C2.PerformedCount);
				}
			}
		}
		
		[Test]
		//test a wrapping issue with time multiplication
		public void WrapMultiplier()
		{
			var p = new UX.Timeline.WrapMultiplier();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				//the timeline may animate the first frame it is rooted (all these timelines should exhibit the 
				//same behaviour)
				var bp = TriggerProgress(p.T1) / p.T1.TimeMultiplier; //back in unscaled domain
				
				for (int i=0; i < 1000; i++)
				{
					root.StepFrame();
					bp += root.StepIncrement;
					Assert.AreEqual( ExpectedProgress(bp, p.T1, 1), TriggerProgress(p.T1));
					Assert.AreEqual( ExpectedProgressInv(bp, p.T3, 1), TriggerProgress(p.T3));
					Assert.AreEqual( ExpectedProgress(bp, p.T2, p.N2.Duration), TriggerProgress(p.T2));
					Assert.AreEqual( ExpectedProgressInv(bp, p.T4, p.N4.Duration), TriggerProgress(p.T4));
				}
			}
		}
		
		[Test]
		//test a wrap with duration < 1
		public void WrapLowDuration()
		{
			var p = new UX.Timeline.WrapLowDuration();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				var time = p.tl.Progress * p.nt.Duration; //will have animated a bit already
				var step = 0.11;
				
				for (double i=0; i < 3.0; i += step)
				{
					root.StepFrame((float)step);
					time += step;
					Assert.AreEqual( Math.Fract(time/p.nt.Duration), p.tl.Progress );
				}
			}
		}
		
		double ExpectedProgress( double time, Timeline t, double duration )
		{
			return Math.Mod(time * t.TimeMultiplier / duration + t.InitialProgress, 1);
		}
		
		double ExpectedProgressInv( double time, Timeline t, double duration )
		{
			return Math.Mod(t.InitialProgress - time * t.TimeMultiplier / duration, 1);
		}
		
		[Test]
		public void JS()
		{
			var p = new UX.Timeline.JS();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual(0,p.T.Progress);
				
				//here we're just establishing the right function was called, the precise timing tests
				//are done elsewhere
				p.Pulse.Perform();
				root.StepFrameJS();
				var ip = p.T.Progress;
				root.StepFrame(2.5f - (float)(ip*p.N.Duration));
				Assert.AreEqual(0.5f, p.T.Progress);
				root.StepFrame(2.5f);
				Assert.AreEqual(1f, p.T.Progress);
				root.StepFrame(2.5f);
				Assert.AreEqual(0.5f, p.T.Progress, root.StepIncrement+ _zeroTolerance);
				root.StepFrame(3f); //overkill
				Assert.AreEqual(0f, p.T.Progress);
				
				p.PulseForward.Perform();
				root.StepFrameJS();
				ip = p.T.Progress;
				root.StepFrame(2.5f - (float)(ip*p.N.Duration));
				Assert.AreEqual(0.5f, p.T.Progress);
				root.StepFrame(1.5f);
				Assert.AreEqual(0.8f, p.T.Progress);
				root.StepFrame(1.01f);
				Assert.AreEqual(0f, p.T.Progress); //back to start
				
				p.PulseBackward.Perform();
				root.StepFrameJS();
				ip = p.T.Progress;
				root.StepFrame((float)(ip*p.N.Duration) - 2.5f);
				Assert.AreEqual(0.5f, p.T.Progress);
				root.StepFrame(1.5f);
				Assert.AreEqual(0.2f, p.T.Progress);
				root.StepFrame(1.01f);
				Assert.AreEqual(0f, p.T.Progress); //stay at start
				
				p.PlayTo5.Perform();
				root.StepFrameJS();
				ip = p.T.Progress;
				root.StepFrame(1.0f - (float)(ip*p.N.Duration));
				p.Pause.Perform();
				root.StepFrameJS();
				root.StepFrame(1);
				Assert.AreEqual(0.2f, p.T.Progress);
				
				p.Resume.Perform();
				root.StepFrameJS();
				ip = p.T.Progress;
				root.StepFrame(2.0f - (float)(ip*p.N.Duration));
				Assert.AreEqual(0.4f, p.T.Progress);
				
				p.Stop.Perform(); //reset TargetDestination...
				root.StepFrameJS();
				p.Play.Perform();
				root.StepFrameJS();
				root.StepFrame(1);
				Assert.AreEqual(0.4f, p.T.Progress); //...thus no further change
				
				p.Seek5.Perform();
				root.StepFrameJS();
				Assert.AreEqual(0.5f, p.T.Progress);
				root.StepFrame(1);
				Assert.AreEqual(0.5f, p.T.Progress);
			}
		}
		
		[Test]
		//copies the logic of JS but using the TimelineAction interface
		public void TimelineAction()
		{
			var p = new UX.Timeline.TimelineAction();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(0,p.T.Progress);
				
				//here we're just establishing the right function was called, the precise timing tests
				//are done elsewhere
				p.Pulse.Pulse();
				root.StepFrame();
				var ip = p.T.Progress;
				root.StepFrame(2.5f - (float)(ip*p.N.Duration));
				Assert.AreEqual(0.5f, p.T.Progress);
				root.StepFrame(2.5f);
				Assert.AreEqual(1f, p.T.Progress);
				root.StepFrame(2.5f);
				Assert.AreEqual(0.5f, p.T.Progress, root.StepIncrement + _zeroTolerance);
				root.StepFrame(3f); //overkill
				Assert.AreEqual(0f, p.T.Progress);
				
				p.PulseForward.Pulse();
				root.StepFrame();
				ip = p.T.Progress;
				root.StepFrame(2.5f - (float)(ip*p.N.Duration));
				Assert.AreEqual(0.5f, p.T.Progress);
				root.StepFrame(1.5f);
				Assert.AreEqual(0.8f, p.T.Progress);
				root.StepFrame(1.01f);
				Assert.AreEqual(0f, p.T.Progress); //back to start
				
				p.PulseBackward.Pulse();
				root.StepFrame();
				ip = p.T.Progress;
				root.StepFrame((float)(ip*p.N.Duration) - 2.5f);
				Assert.AreEqual(0.5f, p.T.Progress);
				root.StepFrame(1.5f);
				Assert.AreEqual(0.2f, p.T.Progress);
				root.StepFrame(1.01f);
				Assert.AreEqual(0f, p.T.Progress); //stay at start
				
				p.PlayTo5.Pulse();
				root.StepFrame();
				ip = p.T.Progress;
				root.StepFrame(1.0f - (float)(ip*p.N.Duration));
				p.Pause.Pulse();
				root.StepFrame(1);
				Assert.AreEqual(0.2f, p.T.Progress, root.StepIncrement);
				
				p.Resume.Pulse();
				root.StepFrame();
				ip = p.T.Progress;
				root.StepFrame(2.0f - (float)(ip*p.N.Duration));
				Assert.AreEqual(0.4f, p.T.Progress);
				
				p.Stop.Pulse(); //reset TargetDestination...
				root.StepFrame();
				p.Play.Pulse();
				root.StepFrame();
				root.StepFrame(1);
				Assert.AreEqual(0.4f, p.T.Progress, root.StepIncrement + _zeroTolerance); //...thus no further change
				
				p.Seek5.Pulse();
				root.StepFrame();
				Assert.AreEqual(0.5f, p.T.Progress);
				root.StepFrame(1);
				Assert.AreEqual(0.5f, p.T.Progress);
			}
		}
	}
}
