using Uno;
using Uno.Collections;
using Uno.Testing;

using Fuse.Animations;
using Fuse.Controls;

using FuseTest;

namespace Fuse.Triggers.Test
{
	public class TriggerTest : TestBase
	{
		const float _zeroTolerance = 1e-05f;

		[Test]
		public void TriggerResources()
		{
			var p = new UX.TriggerResources();
			using (var root = TestRootPanel.CreateWithChild(p, int2(100)))
			{
				Assert.AreEqual("A1", p.t1.Value);
				Assert.AreEqual("A2", p.t2.Value);
				Assert.AreEqual("A1", p.t1_inside.Value);
				Assert.AreEqual("A2", p.t2_inside.Value);
				Assert.AreEqual("A1", p.t1_outside.Value);
				Assert.AreEqual("", p.t2_outside.Value);

				p.WT1.Value = true;
				root.StepFrame();

				Assert.AreEqual("B1", p.t1.Value);
				Assert.AreEqual("B2", p.t2.Value);
				Assert.AreEqual("B1", p.t1_inside.Value);
				Assert.AreEqual("B2", p.t2_inside.Value);
				Assert.AreEqual("A1", p.t1_outside.Value);
				Assert.AreEqual("", p.t2_outside.Value);

				p.WT1.Value = false;
				root.StepFrame();

				Assert.AreEqual("A1", p.t1.Value);
				Assert.AreEqual("A2", p.t2.Value);
				Assert.AreEqual("A1", p.t1_inside.Value);
				Assert.AreEqual("A2", p.t2_inside.Value);
				Assert.AreEqual("A1", p.t1_outside.Value);
				Assert.AreEqual("", p.t2_outside.Value);
			}
		}

		[Test]
		public void GetAnimatorsDurationTest()
		{
			var m = new Move()
			{
				Delay = 0.0f,
				Duration = 1.0f,
				DelayBack = 1.0f,
				DurationBack = 2.0f,
			};
			var s = new Scale()
			{
				Delay = 2.0f,
				Duration = 3.0f,
				DelayBack = 3.0f,
				DurationBack = 4.0f,
			};
			var r = new Rotate()
			{
				Delay = 4.0f,
				Duration = 5.0f,
				DelayBack = 5.0f,
				DurationBack = 6.0f,
			};

			var dt = new DummyTrigger();

			dt.Animators.Add(m);
			dt.Animators.Add(s);
			dt.Animators.Add(r);

			var totalDurationForward = dt.Animation.GetAnimatorsDuration(AnimationVariant.Forward);

			Assert.AreEqual(9.0, totalDurationForward);

			var totalDurationBackward = dt.Animation.GetAnimatorsDuration(AnimationVariant.Backward);

			Assert.AreEqual(11.0, totalDurationBackward);
		}
		
		[Test]
		public void NoChild()
		{
			var p = new UX.NoChild();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				var v = VisualsOf(p);
				Assert.AreEqual(0, v.Count);
				
				p.AT1.Value = true;
				root.PumpDeferred();
				v = VisualsOf(p);
				Assert.AreEqual(1, v.Count);
				
				p.AT1.Value = false;
				root.PumpDeferred();
				v = VisualsOf(p);
				Assert.AreEqual(0, v.Count);
			}
		}
		
		[Test]
		public void ChildOrder1()
		{
			var p = new UX.TriggerOrder();
			using (var root = TestRootPanel.CreateWithChild(p, int2(100)))
			{
				var v = VisualsOf(p.A);
				Assert.AreEqual(0, v.Count);

				p.AT2.Value = true;
				p.AT1.Value = true;
				root.PumpDeferred();
				v = VisualsOf(p.A);
				Assert.AreEqual(2, v.Count);
				Assert.AreEqual(p.A1, v[0]);
				Assert.AreEqual(p.A2, v[1]);

				p.AT3.Value = true;
				p.AT1.Value = false;
				root.PumpDeferred();
				v = VisualsOf(p.A);
				Assert.AreEqual(2, v.Count);
				Assert.AreEqual(p.A2, v[0]);
				Assert.AreEqual(p.A3, v[1]);
			}
		}
		
		[Test]
		public void ChildOrder2()
		{
			var p = new UX.TriggerOrder();
			using (var root = TestRootPanel.CreateWithChild(p, int2(100)))
			{
				var v = VisualsOf(p.B);
				Assert.AreEqual(2, v.Count);

				p.BT1.Value = true;
				v = VisualsOf(p.B);
				Assert.AreEqual(3, v.Count);
				Assert.AreEqual(p.B1, v[0]);
				Assert.AreEqual(p.B2, v[1]);
				Assert.AreEqual(p.B3, v[2]);
			}
		}
			
		[Test]
		public void ChildOrder3()
		{
			var p = new UX.TriggerOrder();
			using (var root = TestRootPanel.CreateWithChild(p, int2(100)))
			{
				var v = VisualsOf(p.C);
				Assert.AreEqual(1, v.Count);

				p.CT1.Value = true;
				root.PumpDeferred();
				v = VisualsOf(p.C);
				Assert.AreEqual(2, v.Count);
				Assert.AreEqual(p.C1, v[0]);
				Assert.AreEqual(p.C2, v[1]);

				p.CT1.Value = false;
				p.CT3.Value = true;
				root.PumpDeferred();
				v = VisualsOf(p.C);
				Assert.AreEqual(2, v.Count);
				Assert.AreEqual(p.C2, v[0]);
				Assert.AreEqual(p.C3, v[1]);
			}
		}
		
		List<Visual> VisualsOf(Visual a)
		{
			var v = new List<Visual>();
			foreach (var c in a.Children)
			{
				if (c is Visual)
					v.Add( c as Visual );
			}
			return v;
		}
		
		[Test]
		/**
			Progress and playback direction should be preserved when `PreserveRootFrame` is used --
			this is part of the Placeholder/MultiLayout feature set.
		*/
		public void PreserveRoot()
		{
			var p = new UX.PreserveRoot();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				p.T1.Pulse();
				p.T2.Pulse();
				p.C.PreserveRootFrame();
				p.P1.Children.Remove(p.C);
				p.P2.Children.Add(p.C);
				root.StepFrame(0.5f);
				Assert.AreEqual(0.5,TriggerProgress(p.T1));
				Assert.AreEqual(0.5,TriggerProgress(p.T2));
				Assert.IsTrue(p.A.IsRootingCompleted);

				p.C.PreserveRootFrame();
				p.P2.Children.Remove(p.C);
				p.P1.Children.Add(p.C);
				root.StepFrame(0.5f);
				Assert.AreEqual(1,TriggerProgress(p.T1));
				Assert.AreEqual(1,TriggerProgress(p.T2));
				root.StepFrame(0.5f);
				//the pulse turnaround could take 1 frame, it's uncertain if this an issue (the 2* is because
				//or stepping may not line up precisely, thus 1-frame delayed as well)
				//NOTE: This is probably an issue, since a pulse trigger takes longer than expected
				//https://github.com/fusetools/fuselibs-private/issues/2005
				var tolerance = 2*root.StepIncrement + _zeroTolerance;
				Assert.AreEqual(0.5f,TriggerProgress(p.T1), tolerance);
				Assert.AreEqual(0.5f,TriggerProgress(p.T2), tolerance);

				root.StepFrame(0.6f); //overshoot
				Assert.AreEqual(0,TriggerProgress(p.T1));
				Assert.AreEqual(0,TriggerProgress(p.T2));
				Assert.IsFalse(p.A.IsRootingCompleted);
			}
		}
		
		[Test]
		/**
			Tests certain boundary conditions with how triggers change directions and trigger actions.
		*/
		public void EdgeAction1()
		{
			var p = new UX.EdgeAction();
			using(var root = TestRootPanel.CreateWithChild(p))
			{
				p.Open.DirectActivate();
				root.PumpDeferred();
				Assert.AreEqual(1, p.AFore.PerformedCount);
				Assert.AreEqual(0, p.ABack.PerformedCount);
				
				p.Open.DirectDeactivate();
				root.PumpDeferred();
				Assert.AreEqual(1, p.AFore.PerformedCount);
				Assert.AreEqual(1, p.ABack.PerformedCount);
				
				p.Open.DirectDeactivate();
				root.PumpDeferred();
				Assert.AreEqual(1, p.AFore.PerformedCount);
				Assert.AreEqual(1, p.ABack.PerformedCount);
				
				root.IncrementFrame();
				Assert.AreEqual(1, p.AFore.PerformedCount);
				Assert.AreEqual(1, p.ABack.PerformedCount);
				
				Assert.IsFalse(p.Content.IsRootingCompleted);
			}
		}
		
		[Test]
		public void EdgeAction2()
		{
			var p = new UX.EdgeAction();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				p.Open.BypassActivate();
				p.Open.DirectActivate();
				Assert.AreEqual(0, p.AFore.PerformedCount);
				Assert.AreEqual(0, p.ABack.PerformedCount);

				root.IncrementFrame();

				p.Open.BypassDeactivate();
				p.Open.DirectDeactivate();
				Assert.AreEqual(0, p.AFore.PerformedCount);
				Assert.AreEqual(0, p.ABack.PerformedCount);
			}
		}
		
		[Test]
		/**
			Tests rerooting in a MultiLayout combined with several actions on a pulse trigger. This
			came up in a use-case where a buton within a MultiLayoutPanel was directly triggering
			the layout change but had other actions/animations of it's own.
			
			This test has no duration, which is a common situation for pulse triggers on buttons.
		*/
		public void PreserveRootActionNoDuration()
		{
			var p = new UX.PreserveRootAction();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				p.T1.Pulse();
				root.PumpDeferred();
				Assert.AreEqual(1, p.AFore1.PerformedCount);
				Assert.AreEqual(1, p.ABack1.PerformedCount);
				Assert.AreEqual(1, p.AFore2.PerformedCount);
				Assert.AreEqual(1, p.ABack2.PerformedCount);
				Assert.AreEqual(p.PL2, p.C.Parent);

				p.T1.Pulse();
				root.PumpDeferred();
				Assert.AreEqual(2, p.AFore1.PerformedCount);
				Assert.AreEqual(2, p.ABack1.PerformedCount);
				Assert.AreEqual(2, p.AFore2.PerformedCount);
				Assert.AreEqual(2, p.ABack2.PerformedCount);
				Assert.AreEqual(p.PL1, p.C.Parent);
			}
		}

		[Test]
		/**
			Variation of previuos using a duration in the trigger with layout change in the middle.
		*/
		public void PreserveRootActionDuration()
		{
			var p = new UX.PreserveRootActionDuration();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				p.T1.Pulse();
				root.StepFrame(2.1f); //overkill for frame imprecision
				Assert.AreEqual(1, p.AFore1.PerformedCount);
				Assert.AreEqual(1, p.ABack1.PerformedCount);
				Assert.AreEqual(1, p.AFore2.PerformedCount);
				Assert.AreEqual(1, p.ABack2.PerformedCount);
				Assert.AreEqual(1, p.AFore3.PerformedCount);
				Assert.AreEqual(1, p.ABack3.PerformedCount);
				Assert.AreEqual(1, p.AFore4.PerformedCount);
				Assert.AreEqual(1, p.ABack4.PerformedCount);
				Assert.AreEqual(p.PL2, p.C.Parent);

				p.T1.Pulse();
				root.StepFrame(2.1f); //overkill for frame imprecision
				Assert.AreEqual(2, p.AFore1.PerformedCount);
				Assert.AreEqual(2, p.ABack1.PerformedCount);
				Assert.AreEqual(2, p.AFore2.PerformedCount);
				Assert.AreEqual(2, p.ABack2.PerformedCount);
				Assert.AreEqual(2, p.AFore3.PerformedCount);
				Assert.AreEqual(2, p.ABack3.PerformedCount);
				Assert.AreEqual(2, p.AFore4.PerformedCount);
				Assert.AreEqual(2, p.ABack4.PerformedCount);
				Assert.AreEqual(p.PL1, p.C.Parent);
			}
		}

		[Test]
		/**
			Checks guarantees about the animation state object being activated at deactivated at the correct
			progress.
		*/
		public void AnimatorStateProgress1()
		{
			var p = new UX.AnimatorState();
			Assert.AreEqual(0,p.A1.Active.Count);
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				for (int i=0; i < 2; ++i)
				{
					p.WT1.Value = true;
					root.IncrementFrame(); //progress is not guaranteed to be sync, only within the same frame
					Assert.AreEqual(1,p.A1.Active.Count);
					var a = p.A1.Active[0];
					Assert.AreEqual(1,TriggerProgress(p.WT1));

					p.WT1.Value = false;
					root.IncrementFrame();
					Assert.AreEqual(0,TriggerProgress(p.WT1));
					Assert.AreEqual(0,p.A1.Active.Count);
					Assert.IsFalse(a.IsActive);
				}
			}
		}

		[Test]
		public void AnimatorStateProgress2()
		{
			var p = new UX.AnimatorState();
			Assert.AreEqual(0,p.A2.Active.Count);
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				//startAtZero should always have it's state
				Assert.AreEqual(1,p.A2.Active.Count);
				var a = p.A2.Active[0];
				p.WT2.Value = true;
				root.IncrementFrame(); //progress is not guaranteed to be sync, only within the same frame
				Assert.AreEqual(a,p.A2.Active[0]);

				p.WT2.Value = false;
				root.IncrementFrame();
				Assert.AreEqual(1,p.A2.Active.Count);
				Assert.IsTrue(a.IsActive);
				Assert.AreEqual(a,p.A2.Active[0]);
			}
		}

		[Test]
		public void AnimatorStateProgress3()
		{
			var p = new UX.AnimatorState();
			Assert.AreEqual(0,p.A3.Active.Count);
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				p.WT3.Value = true;
				root.IncrementFrame(); //progress is not guaranteed to be sync, only within the same frame
				Assert.AreEqual(1,p.A3.Active.Count); //only forward now (expected optimization)
				var a = p.A3.Active[0];

				root.StepFrame(0.5f);
				p.WT3.Value = false;
				root.IncrementFrame();

				Assert.AreEqual(2,p.A3.Active.Count);
				var b = p.A3.Active[1];
				Assert.IsTrue(a.IsActive);
				Assert.IsTrue(b.IsActive);

				root.StepFrame(0.6f); //overkill
				Assert.AreEqual(0,p.A3.Active.Count);
				Assert.IsFalse(a.IsActive);
				Assert.IsFalse(b.IsActive);
			}
		}

		[Test]
		public void AnimatorStateProgress4()
		{
			var p = new UX.AnimatorState();
			Assert.AreEqual(0,p.A4.Active.Count);
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				p.WT4.Value = true;
				root.IncrementFrame(); //progress is not guaranteed to be sync, only within the same frame
				Assert.AreEqual(1,p.A4.Active.Count);
				var a = p.A4.Active[0];
				root.StepFrame(1);
				Assert.AreEqual(1,TriggerProgress(p.WT4));

				p.WT4.Value = false;
				root.StepFrame(1.5f);
				Assert.AreEqual(0,TriggerProgress(p.WT4));
				Assert.AreEqual(1,p.A4.Active.Count); //still active
				Assert.IsTrue(a.IsActive);

				a.AllowStable = true;
				root.IncrementFrame();
				Assert.AreEqual(0,TriggerProgress(p.WT4));
				Assert.AreEqual(0,p.A4.Active.Count);
				Assert.IsFalse(a.IsActive);
			}
		}

		
		[Test]
		/**
			Tests situations where an action has a delay beyond the end of the natural duration.
			https://github.com/fusetools/fuselibs-private/issues/2472
			
			The test here works with the actual playback, not just checking the duration, to ensure it matches the logical expectation, not the implementation detail.
		*/
		public void ActionBeyondEnd()
		{
			var t = new UX.ActionBeyondEnd();
			using (var root = TestRootPanel.CreateWithChild(t))
			{
				//since change-over foreward/backward may be one frame
				var frameOff = root.StepIncrement + _zeroTolerance;

				t.T1.Pulse();
				Assert.AreEqual(0, TriggerProgress(t.T1));
				root.StepFrame(1f);
				Assert.AreEqual(0.5f, TriggerProgress(t.T1));
				root.StepFrame(1f);
				Assert.AreEqual(1f, TriggerProgress(t.T1));
				root.StepFrame(1f);
				Assert.AreEqual(0f, TriggerProgress(t.T1), frameOff);

				t.T2.Pulse();
				Assert.AreEqual(0, TriggerProgress(t.T2));
				root.StepFrame(1f);
				Assert.AreEqual(1f, TriggerProgress(t.T2));
				root.StepFrame(1f);
				Assert.AreEqual(0.5f, TriggerProgress(t.T2), frameOff);
				root.StepFrame(1f);
				Assert.AreEqual(0f, TriggerProgress(t.T2), frameOff);

				t.T3.Pulse();
				Assert.AreEqual(0, TriggerProgress(t.T3));
				root.StepFrame(1f);
				Assert.AreEqual(0.5f, TriggerProgress(t.T3));
				root.StepFrame(1f);
				Assert.AreEqual(1f, TriggerProgress(t.T3));
				root.StepFrame(1f);
				Assert.AreEqual(0.5f, TriggerProgress(t.T3), frameOff);
				root.StepFrame(1f);
				Assert.AreEqual(0f, TriggerProgress(t.T3), frameOff);
			}
		}
		
		[Test]
		public void MatchOrder()
		{
			var t = new UX.TriggerMatchOrder();
			using (var root = TestRootPanel.CreateWithChild(t))
				Assert.AreEqual( "123", GetText(t));
		}
		
		string GetText(Visual root)
		{
			string t = "";
			for (int i=0; i < root.Children.Count; ++i)
			{
				var tx = root.Children[i] as Fuse.Controls.Text;
				if (tx != null)
					t += tx.Value;
			}
			return t;
		}
		
		[Test]
		/* Tests that items inserted via Visual.InsertNodes are part of the same rooting group. */
		public void RootCapture()
		{
			var t = new UX.TriggerRootCapture();
			using (var root = TestRootPanel.CreateWithChild(t))
			{
				t.Out.Value = true;
				//root.IncrementFrame();
				Assert.AreEqual(0,t.T1.PerformedCount);
				Assert.IsTrue(t.W1.Value);
				Assert.AreEqual(0,t.T2.PerformedCount);
			}
		}
		
		[Test]
		public void PlayState()
		{
			var t = new UX.Trigger.PlayState();
			using (var root = TestRootPanel.CreateWithChild(t))
			{
				Assert.AreEqual(0, t.PS.ChangedCount );
				t.PS.Activate();
				Assert.AreEqual(1, t.PS.ChangedCount );
				Assert.AreEqual(TriggerPlayState.Forward, t.PS.PlayState);
				
				t.PS.Deactivate();
				Assert.AreEqual(2, t.PS.ChangedCount );
				//Backward is expected at first even though no time has elapsed in forward, it's to 
				//resolve many trigger conditions/expectations on playback
				Assert.AreEqual(TriggerPlayState.Backward, t.PS.PlayState); 
				
				root.IncrementFrame();
				Assert.AreEqual(3, t.PS.ChangedCount );
				Assert.AreEqual(TriggerPlayState.Stopped, t.PS.PlayState);
				
				t.PS.Activate();
				Assert.AreEqual(4, t.PS.ChangedCount );
				Assert.AreEqual(TriggerPlayState.Forward, t.PS.PlayState);
				
				root.StepFrame(0.5f);
				Assert.AreEqual(4, t.PS.ChangedCount );
				
				root.StepFrame(0.5f + 2*root.StepIncrement); //overkill to account for increment precision
				Assert.AreEqual(5, t.PS.ChangedCount );
				Assert.AreEqual(TriggerPlayState.Stopped, t.PS.PlayState);
				
				t.PS.Activate();
				Assert.AreEqual(5, t.PS.ChangedCount );
				
				t.PS.Deactivate();
				Assert.AreEqual(6, t.PS.ChangedCount );
				Assert.AreEqual(TriggerPlayState.Backward, t.PS.PlayState);
				
				root.StepFrame(0.5f);
				Assert.AreEqual(6, t.PS.ChangedCount );
				
				root.StepFrame(0.5f+ 2 * root.StepIncrement);
				Assert.AreEqual(7, t.PS.ChangedCount );
				Assert.AreEqual(TriggerPlayState.Stopped, t.PS.PlayState);
			}
		}
		
		[Test]
		public void PlayState2()
		{
			var t = new UX.Trigger.PlayState();
			using (var root = TestRootPanel.CreateWithChild(t))
			{
				t.PS.PlayTo(0.5);
				Assert.AreEqual(1, t.PS.ChangedCount );
				Assert.AreEqual(TriggerPlayState.Forward, t.PS.PlayState);
				
				root.StepFrame(0.5f + root.StepIncrement);
				Assert.AreEqual(2, t.PS.ChangedCount );
				Assert.AreEqual(TriggerPlayState.Stopped, t.PS.PlayState);
				
				t.PS.PlayTo(0.5);
				Assert.AreEqual(2, t.PS.ChangedCount );
				
				t.PS.PlayTo(1.0);
				Assert.AreEqual(3, t.PS.ChangedCount );
				Assert.AreEqual(TriggerPlayState.Forward, t.PS.PlayState);
				
				root.StepFrame(1);
				Assert.AreEqual(4, t.PS.ChangedCount );
				Assert.AreEqual(TriggerPlayState.Stopped, t.PS.PlayState);
				
				t.PS.Activate();
				Assert.AreEqual(4, t.PS.ChangedCount );
				
				t.PS.PlayTo(0.5);
				Assert.AreEqual(5, t.PS.ChangedCount );
				Assert.AreEqual(TriggerPlayState.Backward, t.PS.PlayState);
			}
		}
		
		[Test]
		public void PlayStateSeek()
		{
			var t = new UX.Trigger.PlayStateSeek();
			using (var root = TestRootPanel.CreateWithChild(t))
			{
				t.PS.Seek(0.5);
				Assert.AreEqual(0, t.PS.NonSeekChangedCount );
				
				t.PS.PlayTo(1.0);
				root.StepFrame(0.5f + root.StepIncrement);
				Assert.AreEqual(TriggerPlayState.Stopped, t.PS.PlayState);
			}
		}
		
		[Test]
		public void PlayStateSeek2()
		{
			var t = new UX.Trigger.PlayState(); //the one with a duration, not the seek one without
			using (var root = TestRootPanel.CreateWithChild(t))
			{
				t.PS.Seek(0.5);
				Assert.AreEqual(0, t.PS.NonSeekChangedCount );
				
				t.PS.PlayTo(1.0);
				root.StepFrame(0.5f + root.StepIncrement);
				Assert.AreEqual(TriggerPlayState.Stopped, t.PS.PlayState);
			}
		}
		
		[Test]
		public void Template()
		{
			var t = new UX.Trigger.Template();
			using (var root = TestRootPanel.CreateWithChild(t))
			{
				Assert.AreEqual(0,GetChildren<Text>(t).Length);
				
				for (int i=0; i < 3; ++i)
				{
					t.WA.Value = true;
					root.PumpDeferred();
					Assert.AreEqual(1,GetChildren<Text>(t).Length);	
				
					t.WA.Value = false;
					root.PumpDeferred();
					Assert.AreEqual(0,GetChildren<Text>(t).Length);	
				}
			}
		}
		
		[Test]
		public void DeferredRootGroup()
		{
			var t = new UX.Trigger.DeferredRootGroup();
			using (var root = TestRootPanel.CreateWithChild(t))
			{
				Assert.AreEqual( 1, t.W1.Progress );
				Assert.AreEqual( 0, t.W2.Progress );
				Assert.AreEqual( 1, t.D1.Progress );
				Assert.AreEqual( 0, t.L1.Progress );
				
				root.StepFrame(0.5f);
				Assert.AreEqual(0.5, t.L1.Progress );
			}
		}
	}

	public class PlayStateTrigger : Trigger
	{
		public int ChangedCount;
		public int NonSeekChangedCount;
		
		TriggerPlayState _lastState;
		
		protected override void OnPlayStateChanged(TriggerPlayState state)
		{
			Assert.AreNotEqual(_lastState, state);
			_lastState = state;
			
			if (state != TriggerPlayState.SeekForward && state != TriggerPlayState.SeekBackward)
				NonSeekChangedCount++;
				
			ChangedCount++;
		}
		
		public new void Activate() { base.Activate(); }
		public new void Deactivate() { base.Deactivate(); }
		public new void PlayTo(double progress) { base.PlayTo(progress); }
		public new void Seek(double progress) { base.Seek(progress); }
		
		public new TriggerPlayState PlayState { get { return base.PlayState; } }
	}
	
}
