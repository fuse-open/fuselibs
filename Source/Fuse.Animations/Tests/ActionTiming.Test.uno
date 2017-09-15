using Uno;
using Uno.Testing;

using Fuse;
using Fuse.Animations;
using Fuse.Triggers.Actions;

using FuseTest;

class TimingAction : TriggerAction
{
	public int Count;
	
	protected override void Perform(Node target)
	{
		Count++;
	}
}

namespace AnimationTests.Test
{
	public class ActionTiming : TestBase
	{
		[Test]
		public void ForwardBackwardPulse()
		{
			var t = new UX.ActionTiming();
			using (var root = TestRootPanel.CreateWithChild(t))
			{
				t.TheTrigger.Pulse();
				root.IncrementFrame(0.01f); //hmmm.... playback of animation/progress doesn't trigger in the same frame

				Assert.AreEqual(1, t.TaFore.Count);
				Assert.AreEqual(0, t.TaBack.Count);
				Assert.AreEqual(1, t.TaP0.Count);
				Assert.AreEqual(0, t.TaP5.Count);
				Assert.AreEqual(0, t.TaP10.Count);

				root.IncrementFrame(5);
				Assert.AreEqual(1, t.TaFore.Count);
				Assert.AreEqual(0, t.TaBack.Count);
				Assert.AreEqual(1, t.TaP0.Count);
				Assert.AreEqual(1, t.TaP5.Count);
				Assert.AreEqual(0, t.TaP10.Count);

				for (int i=0; i < 3; ++i)
				{
					root.IncrementFrame(5);
					root.IncrementFrame(0.01f); //hmmm...
					root.IncrementFrame(0.01f); //hmmm...
					Assert.AreEqual(1, t.TaFore.Count);
					Assert.AreEqual(1, t.TaBack.Count);
					Assert.AreEqual(1, t.TaP0.Count);
					Assert.AreEqual(1, t.TaP5.Count);
					Assert.AreEqual(1, t.TaP10.Count);
				}
			}
		}
		
		[Test]
		public void MinOnOff()
		{
			var t = new UX.ActionTimingWhile();
			using (var root = TestRootPanel.CreateWithChild(t))
			{
				root.IncrementFrame(1.01f);

				t.TheTrigger.Value = true;
				root.IncrementFrame(2);

				Assert.AreEqual(1, t.TaFore.Count);
				Assert.AreEqual(0, t.TaBack.Count);
				Assert.AreEqual(1, t.TaP0.Count);
				Assert.AreEqual(0, t.TaP5.Count);
				Assert.AreEqual(0, t.TaP10.Count);

				t.TheTrigger.Value = false;
				root.IncrementFrame(0.01f);
				Assert.AreEqual(1, t.TaFore.Count);
				Assert.AreEqual(1, t.TaBack.Count);
				Assert.AreEqual(1, t.TaP0.Count);
				Assert.AreEqual(0, t.TaP5.Count);
				Assert.AreEqual(0, t.TaP10.Count);

				t.TheTrigger.Value = true;
				root.IncrementFrame(0.01f);
				Assert.AreEqual(2, t.TaFore.Count);
				Assert.AreEqual(1, t.TaBack.Count);
				Assert.AreEqual(1, t.TaP0.Count);
				Assert.AreEqual(0, t.TaP5.Count);
				Assert.AreEqual(0, t.TaP10.Count);
			}
		}
		
		[Test]
		public void DoublePulse()
		{
			var t = new UX.ActionTiming();
			using (var root = TestRootPanel.CreateWithChild(t))
			{
				t.TheTrigger.Pulse();
				root.IncrementFrame(0.1f);
				Assert.AreEqual(1, t.TaFore.Count);
				Assert.AreEqual(0, t.TaBack.Count);

				t.TheTrigger.Pulse();
				root.IncrementFrame(0.1f);
				Assert.AreEqual(2, t.TaFore.Count);
				Assert.AreEqual(0, t.TaBack.Count);
			}
		}
		
		[Test]
		public void BeyondEnd()
		{
			var t = new UX.BeyondEnd();
			using (var root = TestRootPanel.CreateWithChild(t))
			{
				root.IncrementFrame(1.01f);

				t.TheTrigger.Value = true;
				root.IncrementFrame(1.01f);
				Assert.AreEqual(1, t.TaP0.Count);
			}
		}
		
		[Test]
		public void BeyondEndBack()
		{
			var t = new UX.BeyondEndBack();
			using (var root = TestRootPanel.CreateWithChild(t))
			{
				root.IncrementFrame(1.01f);

				t.TheTrigger.Value = false;
				root.IncrementFrame(1.01f);
				Assert.AreEqual(1, t.TaP0.Count);
			}
		}
		
		[Test]
		public void ZeroTest()
		{
			var t = new UX.ZeroTest();
			using (var root = TestRootPanel.CreateWithChild(t))
			{
				t.TheTrigger.Pulse();
				root.IncrementFrame(0.01f);
				root.IncrementFrame(0.01f);
				Assert.AreEqual(1, t.TaFore.Count);
				Assert.AreEqual(1, t.TaBack.Count);
				Assert.AreEqual(1, t.TaF0.Count);
				Assert.AreEqual(1, t.TaF1.Count);
				Assert.AreEqual(1, t.TaB0.Count);
				Assert.AreEqual(1, t.TaB1.Count);
			}
		}
		
	}
}
