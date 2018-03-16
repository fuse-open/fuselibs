using Uno;
using Uno.Collections;
using Uno.Testing;

using Fuse.Controls;

using FuseTest;

namespace Fuse.Triggers.Test
{
	public class BusyTest : TestBase
	{
		[Test]
		public void Basic()
		{
			var p = new UX.Busy.Basic();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(0, TriggerProgress(p.W1));
				p.B1.IsBusy = true;
				root.PumpDeferred();
				
				Assert.AreEqual(1, TriggerProgress(p.W1));
				p.B1.IsBusy = false;
				root.PumpDeferred();
				Assert.AreEqual(0, TriggerProgress(p.W1));
				
				p.B2.IsBusy = true;
				root.PumpDeferred();
				Assert.AreEqual(1, TriggerProgress(p.W1));
				
				p.B2.IsBusy = false;
				root.PumpDeferred();
				Assert.AreEqual(0, TriggerProgress(p.W1));
			}
		}
		
		[Test]
		public void Multiple()
		{
			var p = new UX.Busy.Multiple();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				p.B4.IsBusy = true;
				p.B1.IsBusy = true;
				root.PumpDeferred();
				Assert.AreEqual(1,TriggerProgress(p.W1));
				Assert.AreEqual(1,TriggerProgress(p.W2));
				
				p.B4.IsBusy = false;
				root.PumpDeferred();
				Assert.AreEqual(1,TriggerProgress(p.W1));
				Assert.AreEqual(0,TriggerProgress(p.W2));
				
				p.B3.IsBusy = true;
				p.B1.IsBusy = false;
				p.B2.IsBusy = true;
				root.PumpDeferred();
				Assert.AreEqual(1,TriggerProgress(p.W1));
				Assert.AreEqual(1,TriggerProgress(p.W2));
				
				p.B3.IsBusy = false;
				p.B2.IsBusy = false;
				root.PumpDeferred();
				Assert.AreEqual(0,TriggerProgress(p.W1));
				Assert.AreEqual(0,TriggerProgress(p.W2));
			}
		}
		
		[Test]
		public void Rooting()
		{
			var p = new UX.Busy.Rooting();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				p.B1.IsBusy = true;
				root.PumpDeferred();
				
				p.Children.Add(p.B1);
				root.PumpDeferred();
				Assert.AreEqual(1,TriggerProgress(p.W1));
				
				p.Children.Remove(p.B1);
				root.PumpDeferred();
				Assert.AreEqual(0,TriggerProgress(p.W1));
				
				p.Children.Add(p.B1);
				root.PumpDeferred();
				Assert.AreEqual(1,TriggerProgress(p.W1));
			}
		}

		[Test]
		public void JavaScript()
		{
			TestRootPanel.RequireModule<BusyTaskModule>();
			
			var p = new UX.Busy.JavaScript();
			using (var dg = new RecordDiagnosticGuard())
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual(1, TriggerProgress(p.W1));
				
				p.CallDone.Perform();
				root.StepFrameJS();
				Assert.AreEqual(0, TriggerProgress(p.W1));
				
				p.CallBusy.Perform();
				root.StepFrameJS();
				Assert.AreEqual(1, TriggerProgress(p.W1));

				//unrooting the JavaScript should force the BusyTask's to done
				p.P1.Children.Remove(p.P2);
				root.PumpDeferred();
				Assert.AreEqual(0, TriggerProgress(p.W1));

				var diagnostics = dg.DequeueAll();
				Assert.AreEqual(1, diagnostics.Count);
				Assert.Contains("Busy", diagnostics[0].Message);
			}
		}
		
		[Test]
		public void JavaScriptRooting()
		{
			TestRootPanel.RequireModule<BusyTaskModule>();
			var p = new UX.Busy.JavaScriptRooting();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual(0, TriggerProgress(p.W1));
				
				p.CallBusy.Perform();
				root.StepFrameJS();
				Assert.AreEqual(1, TriggerProgress(p.W1));
				
				//unrooting the JavaScript should force BusyTask to done, and stay done on rerooting
				p.Children.Remove(p.P1);
				root.PumpDeferred();
				Assert.AreEqual(0, TriggerProgress(p.W1));
				
				p.Children.Add(p.P1);
				root.PumpDeferred();
				Assert.AreEqual(0, TriggerProgress(p.W1));
			}
		}
		
		[Test]
		public void IsHandled()
		{
			var p = new UX.Busy.IsHandled();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				p.B1.IsBusy = true;
				root.PumpDeferred();
				Assert.AreEqual(0,TriggerProgress(p.W1));
				Assert.AreEqual(1,TriggerProgress(p.W2));
				
				p.B2.IsBusy = true;
				root.PumpDeferred();
				Assert.AreEqual(1,TriggerProgress(p.W1));
				Assert.AreEqual(1,TriggerProgress(p.W3));
			}
		}
		
		[Test]
		public void Activity()
		{
			var p = new UX.Busy.Activity();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				p.B1.IsBusy = true;
				root.PumpDeferred();
				Assert.AreEqual(1,TriggerProgress(p.W1));
				Assert.AreEqual(1,TriggerProgress(p.W2));
				Assert.AreEqual(1,TriggerProgress(p.W3));
				
				p.B1.IsBusy = false;
				p.B2.IsBusy = true;
				root.PumpDeferred();
				Assert.AreEqual(1,TriggerProgress(p.W1));
				Assert.AreEqual(1,TriggerProgress(p.W2));
				Assert.AreEqual(0,TriggerProgress(p.W3));
				
				p.B2.IsBusy = false;
				p.B3.IsBusy = true;
				root.PumpDeferred();
				Assert.AreEqual(0,TriggerProgress(p.W1));
				Assert.AreEqual(0,TriggerProgress(p.W2));
				Assert.AreEqual(1,TriggerProgress(p.W3));
				
				p.B3.IsBusy = false;
				p.B4.IsBusy = true;
				root.PumpDeferred();
				Assert.AreEqual(1,TriggerProgress(p.W1));
				Assert.AreEqual(0,TriggerProgress(p.W2));
				Assert.AreEqual(0,TriggerProgress(p.W3));
			}
		}
		
		[Test]
		public void Match()
		{
			var p = new UX.Busy.Match();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				p.W1.IsBusy = true;
				root.PumpDeferred();
				Assert.AreEqual(1,TriggerProgress(p.D1));
				Assert.AreEqual(1,TriggerProgress(p.P1));
				Assert.AreEqual(0,TriggerProgress(p.D2));
				Assert.AreEqual(0,TriggerProgress(p.P2));
				Assert.AreEqual(0,TriggerProgress(p.O1));
				Assert.AreEqual(0,TriggerProgress(p.O2));
				
				p.W1.IsBusy = false;
				p.W2.IsBusy = true;
				root.PumpDeferred();
				Assert.AreEqual(1,TriggerProgress(p.D1));
				Assert.AreEqual(0,TriggerProgress(p.P1));
				Assert.AreEqual(1,TriggerProgress(p.D2));
				Assert.AreEqual(1,TriggerProgress(p.P2));
				Assert.AreEqual(1,TriggerProgress(p.O1));
				Assert.AreEqual(0,TriggerProgress(p.O2));
				
				p.W2.IsBusy = false;
				p.W3.IsBusy = true;
				root.PumpDeferred();
				Assert.AreEqual(1,TriggerProgress(p.D1));
				Assert.AreEqual(0,TriggerProgress(p.P1));
				Assert.AreEqual(1,TriggerProgress(p.D2));
				Assert.AreEqual(0,TriggerProgress(p.P2));
				Assert.AreEqual(1,TriggerProgress(p.O1));
				Assert.AreEqual(1,TriggerProgress(p.O2));
			}
		}
		
		[Test]
		public void CompletedBasic()
		{
			var p = new UX.Busy.CompletedBasic();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.PumpDeferred();
				Assert.AreEqual(0,p.C1.PerformedCount);
				Assert.AreEqual(1,p.C2.PerformedCount);
				Assert.IsTrue(p.CP2.TestIsClean);
				
				root.IncrementFrame();
				
				p.B1.IsBusy = false;
				root.StepFrame();
				Assert.AreEqual(0,p.C1.PerformedCount);
				Assert.AreEqual(1,p.C2.PerformedCount);
				
				p.B2.IsBusy = false;
				root.IncrementFrame();
				Assert.AreEqual(0,p.C1.PerformedCount); //not yet, this is still the same frame in the test
				Assert.AreEqual(1,p.C2.PerformedCount);

				root.IncrementFrame();
				Assert.AreEqual(1,p.C1.PerformedCount);
				Assert.AreEqual(1,p.C2.PerformedCount);
				Assert.IsTrue(p.CP1.TestIsClean);
				
				//test the it triggers again after unrooting
				root.Children.Remove(p);
				root.Children.Add(p);
				root.PumpDeferred();
				Assert.AreEqual(1,p.C1.PerformedCount);
				Assert.AreEqual(2,p.C2.PerformedCount);
				
				root.IncrementFrame();
				root.IncrementFrame();
				Assert.AreEqual(2,p.C1.PerformedCount);
				Assert.AreEqual(2,p.C2.PerformedCount);
			}
		}
		
		[Test]
		public void CompletedMatch()
		{
			var p = new UX.Busy.CompletedMatch();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				//implied frame increment
				Assert.AreEqual(0,p.C1.PerformedCount);
				root.IncrementFrame(); //for onces in next frame
				Assert.AreEqual(1,p.C1.PerformedCount);
			}
		}
		
		[Test]
		public void CompletedActivity()
		{
			var p = new UX.Busy.CompletedActivity();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(1,p.C1.PerformedCount);
				Assert.AreEqual(0,p.C2.PerformedCount);
			}
		}
		
		[Test]
		public void CompletedRepeat()
		{
			var p = new UX.Busy.CompletedRepeat();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(1,p.C1.PerformedCount);
				Assert.AreEqual(1,p.C2.PerformedCount);
				
				p.B.IsBusy = true;
				root.IncrementFrame();
				p.B.IsBusy = false;
				root.PumpDeferred();
				
				Assert.AreEqual(2,p.C1.PerformedCount);
				Assert.AreEqual(1,p.C2.PerformedCount);
			}
		}
		
		[Test]
		public void CompletedReset()
		{
			var p = new UX.Busy.CompletedResetJS();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.IncrementFrame();
				Assert.AreEqual(1,p.C1.PerformedCount);
				
				p.CallReset.Perform();
				root.StepFrameJS();
				root.IncrementFrame(); //frame-once Completed
				
				Assert.AreEqual(2,p.C1.PerformedCount);
			}
		}
		
		[Test]
		public void Busy()
		{
			var p = new UX.Busy.Busy();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(0,TriggerProgress(p.W));
				
				p.B.IsActive = true;
				root.PumpDeferred();
				Assert.AreEqual(1,TriggerProgress(p.W));
				
				p.Children.Remove(p.B);
				root.PumpDeferred();
				Assert.AreEqual(0,TriggerProgress(p.W));
				
				p.Children.Add(p.B);
				root.PumpDeferred();
				Assert.AreEqual(1,TriggerProgress(p.W));
				
				p.B.IsActive = false;
				root.PumpDeferred();
				Assert.AreEqual(0,TriggerProgress(p.W));
			}
		}
		
		[Test]
		public void OnParameterChanged()
		{
			var p = new UX.Busy.OnParameterChanged();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(1,TriggerProgress(p.W));
				
				p.B.IsActive = false;
				root.PumpDeferred();
				Assert.AreEqual(0,TriggerProgress(p.W));
				
				p.Parameter = "next";
				root.PumpDeferred();
				Assert.AreEqual(1,TriggerProgress(p.W));
				
				p.CallDone.Perform();
				root.StepFrameJS();
				Assert.AreEqual(0,TriggerProgress(p.W));
			}
		}
		
		[Test]
		public void Js()
		{
			var p = new UX.Busy.Js();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual(0,TriggerProgress(p.W));
				
				p.CallStart.Perform();
				root.StepFrameJS();
				Assert.AreEqual(1,TriggerProgress(p.W));
				
				//this probably tests way more than the Busy+JS interface
				root.Children.Remove(p);
				root.StepFrame();
				root.Children.Add(p);
				root.StepFrameJS();
				Assert.AreEqual(0,TriggerProgress(p.W));
			}
		}
		
		[Test]
		//minimal test for https://github.com/fusetools/fuselibs-private/issues/3532
		public void Removed()
		{
			var p = new UX.Busy.Removed();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(p, p.P.Parent);
				
				p.B1.IsActive = false;
				root.StepFrame();
				Assert.AreEqual(null, p.P.Parent);
			}
		}
	}
}
