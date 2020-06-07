using Uno;
using Uno.Compiler;
using Uno.Testing;
using Uno.UX;

using FuseTest;

using Fuse.Elements;

namespace Fuse.Navigation.Test
{
	public class ActivatedTest : TestBase
	{
		[Test]
		public void Deep()
		{
			var p = new UX.Activated.Deep();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(1,p.AP1.A.PerformedCount);
				Assert.AreEqual(0,p.AP1.D.PerformedCount);
				Assert.AreEqual(0,p.AP2.A.PerformedCount);
				Assert.AreEqual(0,p.AP2.D.PerformedCount);

				Assert.AreEqual(1,p.BP1.A.PerformedCount);
				Assert.AreEqual(0,p.BP1.D.PerformedCount);
				Assert.AreEqual(0,p.BP2.A.PerformedCount);
				Assert.AreEqual(0,p.BP2.D.PerformedCount);

				Assert.AreEqual(1,p.CP1.A.PerformedCount);
				Assert.AreEqual(0,p.CP1.D.PerformedCount);
				Assert.AreEqual(0,p.CP2.A.PerformedCount);
				Assert.AreEqual(0,p.CP2.D.PerformedCount);

				p.Step1.Perform();
				root.StepFrameJS();
				Assert.AreEqual(1,p.AP1.A.PerformedCount);
				Assert.AreEqual(1,p.AP1.D.PerformedCount);
				Assert.AreEqual(1,p.AP2.A.PerformedCount);
				Assert.AreEqual(0,p.AP2.D.PerformedCount);

				Assert.AreEqual(1,p.BP1.A.PerformedCount);
				Assert.AreEqual(1,p.BP1.D.PerformedCount);
				Assert.AreEqual(0,p.BP2.A.PerformedCount);
				Assert.AreEqual(0,p.BP2.D.PerformedCount);

				Assert.AreEqual(1,p.CP1.A.PerformedCount);
				Assert.AreEqual(1,p.CP1.D.PerformedCount);
				Assert.AreEqual(0,p.CP2.A.PerformedCount);
				Assert.AreEqual(0,p.CP2.D.PerformedCount);

				p.Step2.Perform();
				root.StepFrameJS();
				Assert.AreEqual(1,p.A.PerformedCount);
				Assert.AreEqual(1,p.D.PerformedCount);
				Assert.AreEqual(2,p.AP1.A.PerformedCount);
				Assert.AreEqual(1,p.AP1.D.PerformedCount);
				Assert.AreEqual(1,p.AP2.A.PerformedCount);
				Assert.AreEqual(1,p.AP2.D.PerformedCount);

				//requires the full-path single activation to work, otherwise the two next values might be erroneously 2
				Assert.AreEqual(1,p.BP1.A.PerformedCount);
				Assert.AreEqual(1,p.BP1.D.PerformedCount);
				Assert.AreEqual(1,p.BP2.A.PerformedCount);
				Assert.AreEqual(0,p.BP2.D.PerformedCount);

				Assert.AreEqual(1,p.CP1.A.PerformedCount);
				Assert.AreEqual(1,p.CP1.D.PerformedCount);
				Assert.AreEqual(0,p.CP2.A.PerformedCount);
				Assert.AreEqual(0,p.CP2.D.PerformedCount);
			}
		}

		[Test]
		/** Testing of De/Activated events via a Router using a Navigator */
		public void RouterNavigatorActivated()
		{
			var p  = new UX.Activated.RouterNavigator();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual( "", p.Act.Value );
				Assert.AreEqual( "", p.Deact.Value );

				p.router.Goto( new Route("P1"));
				root.StepFrameJS();
				Assert.AreEqual( "1", p.Act.Value );
				Assert.AreEqual( "", p.Deact.Value );

				p.router.Push( new Route("P2"));
				root.StepFrameJS();
				Assert.AreEqual( "12", p.Act.Value );
				Assert.AreEqual( "1", p.Deact.Value );

				p.router.GoBack();;
				root.StepFrameJS();
				Assert.AreEqual( "121", p.Act.Value );
				Assert.AreEqual( "12", p.Deact.Value );
			}
		}

		[Test]
		public void Timing()
		{
			var p = new UX.Activated.Timing();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(1, p.AP1.A.PerformedCount);
				Assert.AreEqual(0, p.AP1.D.PerformedCount);
				Assert.AreEqual(0, p.AP2.A.PerformedCount);
				Assert.AreEqual(0, p.AP2.D.PerformedCount);

				Assert.AreEqual(1, p.AP1.QA.PerformedCount);
				Assert.AreEqual(0, p.AP1.QD.PerformedCount);
				Assert.AreEqual(0, p.AP2.QA.PerformedCount);
				Assert.AreEqual(0, p.AP2.QD.PerformedCount);

				//does an animated transition
				p.Step1.Perform();
				root.StepFrameJS();
				Assert.AreEqual(1, p.AP1.QD.PerformedCount);
				Assert.AreEqual(1, p.AP2.QA.PerformedCount);
				root.StepFrame(0.5f);
				Assert.AreEqual(0, p.AP1.D.PerformedCount);
				Assert.AreEqual(0, p.AP2.A.PerformedCount);

				root.StepFrame(0.55f);
				Assert.AreEqual(1, p.AP1.D.PerformedCount);
				Assert.AreEqual(1, p.AP2.A.PerformedCount);
				Assert.AreEqual(1, p.AP1.QD.PerformedCount);
				Assert.AreEqual(1, p.AP2.QA.PerformedCount);

				//skips the transition
				p.Step2.Perform();
				root.StepFrameJS();
				Assert.AreEqual(2, p.AP1.A.PerformedCount);
				Assert.AreEqual(1, p.AP2.D.PerformedCount);
				Assert.AreEqual(2, p.AP1.QA.PerformedCount);
				Assert.AreEqual(1, p.AP2.QD.PerformedCount);
			}
		}

		[Test]
		//should behave the same as Timing which uses a Navigator
		public void PageControlTiming()
		{
			var p = new UX.Activated.PageControlTiming();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(1, p.AP1.A.PerformedCount);
				Assert.AreEqual(0, p.AP1.D.PerformedCount);
				Assert.AreEqual(0, p.AP2.A.PerformedCount);
				Assert.AreEqual(0, p.AP2.D.PerformedCount);

				Assert.AreEqual(1, p.AP1.QA.PerformedCount);
				Assert.AreEqual(0, p.AP1.QD.PerformedCount);
				Assert.AreEqual(0, p.AP2.QA.PerformedCount);
				Assert.AreEqual(0, p.AP2.QD.PerformedCount);

				//does an animated transition
				p.Step1.Perform();
				root.StepFrameJS();
				Assert.AreEqual(1, p.AP1.QD.PerformedCount);
				Assert.AreEqual(1, p.AP2.QA.PerformedCount);
				root.StepFrame(0.5f);
				Assert.AreEqual(0, p.AP1.D.PerformedCount);
				Assert.AreEqual(0, p.AP2.A.PerformedCount);

				root.StepFrame(0.55f);
				Assert.AreEqual(1, p.AP1.D.PerformedCount);
				Assert.AreEqual(1, p.AP2.A.PerformedCount);
				Assert.AreEqual(1, p.AP1.QD.PerformedCount);
				Assert.AreEqual(1, p.AP2.QA.PerformedCount);

				//skips the transition
				p.Step2.Perform();
				root.StepFrameJS();
				Assert.AreEqual(2, p.AP1.A.PerformedCount);
				Assert.AreEqual(1, p.AP2.D.PerformedCount);
				Assert.AreEqual(2, p.AP1.QA.PerformedCount);
				Assert.AreEqual(1, p.AP2.QD.PerformedCount);
			}
		}

		[Test, Ignore("https://github.com/fuse-open/fuselibs/issues/769")]
		public void LinearActivated()
		{
			var p = new UX.Activated.Linear();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual( "1", p.Act.Value );
				Assert.AreEqual( "", p.Deact.Value);

				p.Nav.Active = p.P2;
				root.StepFrameJS();
				Assert.AreEqual( "12", p.Act.Value );
				Assert.AreEqual( "1", p.Deact.Value);

				p.Nav.Goto(p.P3, NavigationGotoMode.Transition);
				root.StepFrame(5); //stabalize animation
				root.StepFrameJS();
				Assert.AreEqual( "123", p.Act.Value );
				Assert.AreEqual( "12", p.Deact.Value);

				p.Nav.Goto(p.P4, NavigationGotoMode.Bypass);
				root.StepFrameJS();
				Assert.AreEqual( "1234", p.Act.Value );
				Assert.AreEqual( "123", p.Deact.Value);

				//no change
				p.Nav.Active = p.P4;
				root.StepFrameJS();
				Assert.AreEqual( "1234", p.Act.Value );
				Assert.AreEqual( "123", p.Deact.Value);

				//reuse
				p.Nav.Active = p.P1;
				root.StepFrame(2); //account for duration
				root.StepFrameJS();
				Assert.AreEqual( "12341", p.Act.Value );
				Assert.AreEqual( "1234", p.Deact.Value);

				//should go to P2
				p.Nav.GoBack();
				root.StepFrameJS();
				Assert.AreEqual( "123412", p.Act.Value );
				Assert.AreEqual( "12341", p.Deact.Value);

				//null should work
				p.Nav.Active = null;
				root.StepFrameJS();
				Assert.AreEqual( "123412", p.Act.Value );
				Assert.AreEqual( "123412", p.Deact.Value);
			}
		}

		[Test]
		/** A smaller variant of  LinearActivated using a PageControl. This ensures Pagecontrol is forwarding
			things correctly. */
		public void PageControlActivated()
		{
			var p = new UX.Activated.PageControl();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual( "1", p.Act.Value );
				Assert.AreEqual( "", p.Deact.Value);

				p.Nav.Active = p.P2;
				root.StepFrameJS();
				Assert.AreEqual( "12", p.Act.Value );
				Assert.AreEqual( "1", p.Deact.Value);

				p.Nav.Goto(p.P3, NavigationGotoMode.Transition);
				root.StepFrame(5); //stabalize animation
				root.StepFrameJS();
				Assert.AreEqual( "123", p.Act.Value );
				Assert.AreEqual( "12", p.Deact.Value);
			}
		}

		[Test]
		//tracking down https://github.com/fuse-open/fuselibs/issues/223
		public void EdgeNavigator()
		{
			var p = new UX.Activated.EdgeNavigator();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( 1, p.AP1.LA.PerformedCount );
 				Assert.AreEqual( 0, p.AP1.LD.PerformedCount );
				Assert.AreEqual( 1, p.AP1.FA.PerformedCount );
 				Assert.AreEqual( 0, p.AP1.FD.PerformedCount );

 				Assert.AreEqual( 1, p.AP1.LWA.Progress );
 				Assert.AreEqual( 1, p.AP1.FWA.Progress );

 				p.edge.Active = p.left;
 				root.StepFrame(1);

				Assert.AreEqual( 1, p.AP1.LA.PerformedCount );
 				Assert.AreEqual( 0, p.AP1.LD.PerformedCount );
				Assert.AreEqual( 1, p.AP1.FA.PerformedCount );
 				Assert.AreEqual( 1, p.AP1.FD.PerformedCount );

 				Assert.AreEqual( 1, p.AP1.LWA.Progress );
 				Assert.AreEqual( 0, p.AP1.FWA.Progress );

 				p.A1.Active = p.AP2;
 				root.StepFrame(1); //TODO: it's uncertain why PumpDeferred doesn't work here

				Assert.AreEqual( 1, p.AP1.LA.PerformedCount );
 				Assert.AreEqual( 1, p.AP1.LD.PerformedCount );
				Assert.AreEqual( 1, p.AP1.FA.PerformedCount );
 				Assert.AreEqual( 1, p.AP1.FD.PerformedCount );

 				Assert.AreEqual( 0, p.AP1.LWA.Progress );
 				Assert.AreEqual( 0, p.AP1.FWA.Progress );

 				p.A1.Active = p.AP1;
 				root.StepFrame(1);

				Assert.AreEqual( 2, p.AP1.LA.PerformedCount );
 				Assert.AreEqual( 1, p.AP1.LD.PerformedCount );
				Assert.AreEqual( 1, p.AP1.FA.PerformedCount );
 				Assert.AreEqual( 1, p.AP1.FD.PerformedCount );

 				Assert.AreEqual( 1, p.AP1.LWA.Progress );
 				Assert.AreEqual( 0, p.AP1.FWA.Progress );

 				p.edge.Navigation.GoBack();
 				root.StepFrame(1);

				Assert.AreEqual( 2, p.AP1.LA.PerformedCount );
 				Assert.AreEqual( 1, p.AP1.LD.PerformedCount );
				Assert.AreEqual( 2, p.AP1.FA.PerformedCount );
 				Assert.AreEqual( 1, p.AP1.FD.PerformedCount );

 				Assert.AreEqual( 1, p.AP1.LWA.Progress );
 				Assert.AreEqual( 1, p.AP1.FWA.Progress );
			}
		}
	}
}
