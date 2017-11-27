using Uno;
using Uno.UX;
using Uno.Testing;
using FuseTest;

namespace Fuse.Reactive.Test
{
	public class TimerTest : TestBase
	{
		[Test]
		public void ZeroDelayAndRepeat()
		{
			var e = new UX.TimerTest(0, 10000, true);
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				// StepFrameJS will call WaitIdle() on ThreadWorker, which will
				// block until the worker queue is idle. ThreadWorker should not be idle
				// until the Timer has run 10000 times
				root.StepFrameJS();
				Assert.AreEqual(10000, e.IterationCount.Value);
			}
		}
	}
}
