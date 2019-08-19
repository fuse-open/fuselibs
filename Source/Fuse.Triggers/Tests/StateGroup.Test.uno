using Uno;
using Uno.Testing;

using FuseTest;

namespace Fuse.Triggers.Test
{
	public class StateGroupTest : TestBase
	{
		const float _zeroTolerance = 1e-05f;

		[Test]
		public void ChainedSwitch()
		{
			var p = new UX.StateGroupChainedSwitch();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				p.SG.Active = p.B;
				root.IncrementFrame();
				Assert.AreEqual(p.C,p.SG.Active);
				Assert.IsFalse(p.A.On);
				Assert.IsFalse(p.B.On);
				Assert.IsTrue(p.C.On);
				Assert.IsFalse(p.D.On);
			}
		}

		[Test]
		public void Transition()
		{
			var p = new UX.StateGroupTransition();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				p.SG1.Active = p.B1;
				p.SG2.Active = p.B2;
				root.StepFrame(0.5f);

				var eps = root.StepIncrement + _zeroTolerance; //may be off a frame here (other tests check correctness of this)
				Assert.AreEqual(0.5, TriggerProgress(p.A1), eps);
				Assert.AreEqual(0.5, TriggerProgress(p.B1), eps);
				Assert.AreEqual(0.5, TriggerProgress(p.A2), eps);
				Assert.AreEqual(0, TriggerProgress(p.B2), eps);

				root.StepFrame(0.5f);
				Assert.AreEqual(0, TriggerProgress(p.A1), eps);
				Assert.AreEqual(1, TriggerProgress(p.B1), eps);
				Assert.AreEqual(0, TriggerProgress(p.A2), eps);
				Assert.AreEqual(0, TriggerProgress(p.B2), eps);

				root.StepFrame(0.5f);
				Assert.AreEqual(0, TriggerProgress(p.A1), eps);
				Assert.AreEqual(1, TriggerProgress(p.B1), eps);
				Assert.AreEqual(0, TriggerProgress(p.A2), eps);
				Assert.AreEqual(0.5, TriggerProgress(p.B2), eps + root.StepIncrement*2); //TODO: this seems to be too many frames off now
			}
		}
		
		[Test]
		//a timing issue found in https://github.com/fusetools/fuselibs-private/issues/3489
		public void EmptyTiming()
		{
			var p = new UX.StateGroup.EmptyTiming();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(1,TriggerProgress(p.A));
				Assert.AreEqual(0,TriggerProgress(p.B));
				
				p.SG.Active = p.B;
				root.PumpDeferred();
				Assert.AreEqual(0,TriggerProgress(p.A));
				Assert.AreEqual(0,TriggerProgress(p.B));
				Assert.AreEqual(TriggerPlayState.Forward, p.B.PlayState);
				
 				Assert.AreEqual(1, p.C1.PerformedCount);
 				Assert.AreEqual(0, p.C2.PerformedCount);
				Assert.AreEqual(1, p.C3.PerformedCount);
				Assert.AreEqual(0, p.C4.PerformedCount);
				
				root.StepFrame(0.5f);
				Assert.AreEqual(0.5f,TriggerProgress(p.B));
			}
		}
		
		[Test]
		public void Root()
		{
			var p = new UX.StateGroup.Root();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(p.A, p.SG.Active);
				Assert.AreEqual(1, TriggerProgress(p.A));
				p.B.Goto();
				Assert.AreEqual(p.B, p.SG.Active);
				
				root.PumpDeferred();
				Assert.AreEqual(0, TriggerProgress(p.A));
				Assert.AreEqual(1, TriggerProgress(p.B));
				
				p.Children.Remove(p.SG);
				root.IncrementFrame();
				p.Children.Add(p.SG);
				Assert.AreEqual(p.B, p.SG.Active);
				Assert.AreEqual(0, TriggerProgress(p.A));
				Assert.AreEqual(1, TriggerProgress(p.B));
			}
		}
		
		[Test]
		public void Interrupt()
		{
			var p = new UX.StateGroup.Interrupt();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				var eps = root.StepIncrement + _zeroTolerance;
				
				Assert.AreEqual(p.A, p.SG.Active);
				Assert.AreEqual(1, TriggerProgress(p.A));
				p.B.Goto();
				Assert.AreEqual(p.B, p.SG.Active);
				root.StepFrame(0.5f);
				
				Assert.AreEqual(0.5f, TriggerProgress(p.A), eps);
				Assert.AreEqual(0f, TriggerProgress(p.B));
				
				eps += 2*root.StepIncrement; //drifting 1-2 frames on each switch
				p.C.Goto();
				Assert.AreEqual(p.C, p.SG.Active);
				root.StepFrame(1f);
				Assert.AreEqual(0f, TriggerProgress(p.A));
				Assert.AreEqual(0f, TriggerProgress(p.B));
				Assert.AreEqual(0.5f, TriggerProgress(p.C), eps);
			}
		}
		
		[Test]
		public void TransitionState()
		{
			var p = new UX.StateGroup.TransitionState();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(p.s1,p.sg.Active);
				
				p.t1.Pulse();
				root.PumpDeferred();
				Assert.AreEqual(p.s2,p.sg.Active);
			}
		}

		[Test]
		public void TransitionStateValue()
		{
			var p = new UX.StateGroup.TransitionStateValue();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(p.s1,p.sg.Active);
				
				p.t1.Pulse();
				root.PumpDeferred();
				Assert.AreEqual(p.s3,p.sg.Active);
			}
		}
	}
}
