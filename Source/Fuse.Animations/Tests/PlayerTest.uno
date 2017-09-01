using Uno;
using Uno.Testing;

using FuseTest;

namespace Fuse.Animations.Test
{
	public class PlayerTest : TestBase
	{
		[Test]
		public void StableClosed()
		{
			var p = new UX.PlayerClosed();
			using (var root = TestRootPanel.CreateWithChild(p, int2(100,1000)))
			{
				var player = p.A1.CreatePlayer(p);
				try
				{

					Assert.AreEqual(0, player.Progress);
					Assert.AreEqual(1, player.RemainTime);

					Assert.IsFalse(player.TestIsStarted);

					player.PlayToEnd();
					Assert.IsTrue(player.TestIsStarted);

					root.StepFrame(0.2f);
					Assert.AreEqual(0.2f, player.Progress);

					root.StepFrame(0.9f);
					Assert.AreEqual(1f, player.Progress);
					Assert.IsFalse(player.TestIsStarted);
				}
				finally
				{
					player.Disable();
				}
			}
		}
		
		[Test]
		public void StableOpen()
		{
			var p = new UX.PlayerOpen();
			using (var root = TestRootPanel.CreateWithChild(p, int2(100,1000)))
			{
				var player = p.A1.CreatePlayer(p);
				Assert.IsFalse(player.TestIsStarted);

				player.PlayToEnd();
				Assert.IsTrue(player.TestIsStarted);

				root.StepFrame(1);
				Assert.AreEqual(0.2f,player.Progress);
				root.StepFrame(5);
				Assert.AreEqual(1f,player.Progress);

				//no new progress but still animating the open Spin
				root.StepFrame(0.5f);
				Assert.AreEqual(1f,player.Progress);
				Assert.IsTrue(player.TestIsStarted);

				//start backwards, progress updates immmediately, even if spin not done.
				player.PlayToProgress(0.8f);
				root.StepFrame(0.5f);
				Assert.AreEqual(0.9f,player.Progress);

				//long enough for spin to finish
				root.StepFrame(1);
				Assert.AreEqual(0.8f,player.Progress);
				Assert.IsFalse(player.TestIsStarted);
			}
		}
	}
}
