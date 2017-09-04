using Uno;
using Uno.Testing;

using FuseTest;

namespace Fuse.Triggers.Test
{
	public class AddingAnimationTest : TestBase
	{
		[Test]
		public void DelayFrameTest()
		{
			//don't use CreateWithChild to control first frame increment
			var p = new UX.AddingAnimation();
			using (var root = new TestRootPanel())
			{
				root.SetLayoutSize(int2(100));
				root.IncrementFrame(0.1f); //avoid uncertain first frame

				root.Children.Add(p);

				root.IncrementFrame(0.1f);

				Assert.AreEqual(1.0f, TriggerProgress(p.A1));
				Assert.AreEqual(0.9f, TriggerProgress(p.A2));

				root.IncrementFrame(0.1f);
				//it's undefined now whether the first frame of animation is actually considered as time elapse,
				//at this moment it isn't in the delayed case, thus the extra step. But if that changes this can
				//change as well.
				root.IncrementFrame(0.1f);
				Assert.AreEqual(0.9f, TriggerProgress(p.A1));
				Assert.AreEqual(0.7f, TriggerProgress(p.A2)); //0.8 maybe (refer above note)
			}
		}
	}
}
