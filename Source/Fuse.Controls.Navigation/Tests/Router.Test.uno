using Uno;
using Uno.Testing;
using Uno.UX;

using FuseTest;

using Fuse.Elements;

namespace Fuse.Navigation.Test
{
	public class RouterTest : TestBase
	{
		[Test]
		public void Basic()
		{
			Router.TestClearMasterRoute();
			var p = new UX.RouterTest();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "two/b", p.routerA.GetCurrentRoute().Format() ); 
				
				p.routerA.Goto( new Route("one"));
				root.StepFrame(5); //stabilse animation (it's undefined precisely when the route changes)
				Assert.AreEqual( "one/ii", p.routerA.GetCurrentRoute().Format() ); 

				p.routerA.Push( new Route("one", null, new Route( "iii")));
				root.StepFrame(5);
				Assert.AreEqual( "one/iii/bee", p.routerA.GetCurrentRoute().Format() ); 
				
				p.routerA.Push( new Route("one", null, new Route( "i")));
				root.StepFrame(5);
				Assert.AreEqual( "one/i", p.routerA.GetCurrentRoute().Format() ); 
				
				p.routerA.GoBack();
				root.StepFrame(5);
				Assert.AreEqual( "one/iii/bee", p.routerA.GetCurrentRoute().Format() );
				
				p.routerA.GoBack();
				root.StepFrame(5);
				Assert.AreEqual( "one/ii", p.routerA.GetCurrentRoute().Format() );
				
				Assert.IsFalse(p.routerA.CanGoBack);
			}
		}
		
		[Test]
		public void SelfChange()
		{
			Router.TestClearMasterRoute();
			var p = new UX.RouterTest();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( null, p.routerB.GetCurrentRoute().Path );
				
				p.routerB.Goto( new Route( "two" ) );
				root.StepFrame(5);
				Assert.AreEqual( "two/c1", p.routerB.GetCurrentRoute().Format() ); 
				
				var two = p.N2.Active as UX.TemplateTwo;
				two.PC2.Active = two.c3; //change outside of router
				root.StepFrame(5);
				Assert.AreEqual( "two/c3", p.routerB.GetCurrentRoute().Format() ); 
				
				p.routerB.Push( new Route( "one", "dog" ) );
				root.StepFrame(5);
				Assert.AreEqual( "one?dog", p.routerB.GetCurrentRoute().Format() ); 
				
				p.routerB.GoBack();
				root.StepFrame(5);
				Assert.AreEqual( "two/c3", p.routerB.GetCurrentRoute().Format() ); 
			}
		}
		
		[Test]
		/* kind of a clunky feature, but it should be tested nonetheless */
		public void MasterState()
		{
			Router.TestClearMasterRoute();
			var p = new UX.MasterRoute();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				p.Master.Goto( new Route( "one" ) );
				p.Master.Push( new Route( "two", "chum", new Route( "b" ) ) );
				p.Master.Push( new Route( "two", "burp", new Route( "b" ) ) );
				root.PumpDeferred();

				//Route survives destruction
				root.Children.Remove(p);
				p = new UX.MasterRoute();
				root.Children.Add(p);
				root.IncrementFrame();
				
				Assert.AreEqual( "two?burp/b", p.Master.GetCurrentRoute().Format() ); 
				
				p.Master.GoBack();
				root.IncrementFrame();
				Assert.AreEqual( "two?chum/b", p.Master.GetCurrentRoute().Format() ); 
			}
		}
		
		[Test]
		/* checks a router that is inside the routing path of another router */
		public void Embedded()
		{
			Router.TestClearMasterRoute();
			var p = new UX.RouterEmbed();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				p.routerA.Goto( new Route( "one" ) );
				root.PumpDeferred();
				Assert.AreEqual( "one", p.routerA.GetCurrentRoute().Format() );
				Assert.AreEqual( "three", p.routerB.GetCurrentRoute().Format() );
				
				p.routerB.Goto( new Route( "two" ) );
				root.PumpDeferred();
				Assert.AreEqual( "one", p.routerA.GetCurrentRoute().Format() );
				Assert.AreEqual( "two", p.routerB.GetCurrentRoute().Format() );
				
				using (var dg = new RecordDiagnosticGuard())
				{
					p.routerA.Goto( new Route( "two", "", new Route("three") ) );
					root.IncrementFrame();

					var diagnostics = dg.DequeueAll();
					Assert.AreEqual(2, diagnostics.Count);
					Assert.IsTrue( diagnostics[0].Message.IndexOf( "No router outlet" ) != -1 );
					Assert.IsTrue( diagnostics[1].Message.IndexOf( "Unable to navigate to route" ) != -1 );
				}
			}
		}
		
		[Test]
		public void Relative()
		{
			Router.TestClearMasterRoute();
			var p = new UX.Router.Relative();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "One", p.router.GetCurrentRoute().Format() );
				
				p.N.GotoTwo.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "Two/One", p.router.GetCurrentRoute().Format() );
				
				//Navigator will add a new child with JS, thus wait again
				root.StepFrameJS();
				p.N.theNav.FirstChild<SubNav>().GotoTwo.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "Two/Two/One", p.router.GetCurrentRoute().Format() );
				
				root.StepFrameJS();
				p.N.theNav.FirstChild<SubNav>().theNav.FirstChild<SubNav>().PushTwo.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "Two/Two/Two/One", p.router.GetCurrentRoute().Format() );
				
				root.StepFrameJS();
				p.N.theNav.FirstChild<SubNav>().PushOne.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "Two/One", p.router.GetCurrentRoute().Format() );
			}
		}
		
		[Test]
		//https://github.com/fusetools/fuselibs/issues/3689
		public void RelativeNonCurrent()
		{
			Router.TestClearMasterRoute();
			var p = new UX.Router.RelativeNonCurrent();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual("one/", p.router.GetCurrentRoute().Format());
				Assert.AreEqual("two/a", p.router.GetRelativeRoute(p.a, new Route("a")).Format());
				Assert.AreEqual("two/a", p.router.GetRelativeRoute(p.iNav2, new Route("a")).Format());
				Assert.AreEqual("two/b", p.router.GetRelativeRoute(p.a, new Route("b")).Format());
				Assert.AreEqual("one/b", p.router.GetRelativeRoute(p.one.b, new Route("b")).Format());
				Assert.AreEqual("none", p.router.GetRelativeRoute(p.one, new Route("none")).Format());
				
				p.router.Goto( new Route("three") );
				
				Assert.AreEqual("three", p.router.GetCurrentRoute().Format());
				Assert.AreEqual("two/a", p.router.GetRelativeRoute(p.a, new Route("a")).Format());
				Assert.AreEqual("two/b", p.router.GetRelativeRoute(p.a, new Route("b")).Format());
				Assert.AreEqual("one/b", p.router.GetRelativeRoute(p.one.b, new Route("b")).Format());
				
				p.Step1.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "two/a", p.router.GetCurrentRoute().Format());
			}
		}
		
		[Test]
		public void Modify()
		{
			Router.TestClearMasterRoute();
			var p = new UX.Router.Modify();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				p.GoA.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "P2?{}/P3?{}", p.router.GetCurrentRoute().Format() );
				Assert.AreEqual( 1, p.router.TestHistoryCount );
				
				p.GoB.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "P2?{}/P4?{}", p.router.GetCurrentRoute().Format() );
				Assert.AreEqual( 1, p.router.TestHistoryCount );
				
				root.StepFrame(5); //stabilize any animation
				
				p.GoC.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "P1", p.router.GetCurrentRoute().Format() );
				Assert.AreEqual( 0, p.router.TestHistoryCount );
				Assert.AreEqual( 0, (p.C1 as INavigation).PageProgress ); //tests the Bypass part
			}
		}
		
		[Test]
		public void RelativeNest()
		{
			Router.TestClearMasterRoute();
			var p = new UX.Router.RelativeNest();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "one", p.router.GetCurrentRoute().Format() );
				Assert.AreEqual( "i1", p.inner.GetCurrentRoute().Format() );
				
				p.GotoTwo.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "two", p.router.GetCurrentRoute().Format() );
				Assert.AreEqual( "i1", p.inner.GetCurrentRoute().Format() );
				
				p.GotoI2.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "two", p.router.GetCurrentRoute().Format() );
				Assert.AreEqual( "i2/n1", p.inner.GetCurrentRoute().Format() );
				
				//make inner non-current
				p.PushOne.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "one", p.router.GetCurrentRoute().Format() );
				Assert.AreEqual( "i2/n1", p.inner.GetCurrentRoute().Format() );
				
				p.GotoN2.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "one", p.router.GetCurrentRoute().Format() );
				Assert.AreEqual( "i2/n2", p.inner.GetCurrentRoute().Format() );
				
				//A few tests on the relative node checks of the internal functions
				Assert.AreEqual( "q", p.router.GetRelativeRoute(p.one, new Route("q")).Format() );
				Assert.AreEqual( "q", p.router.GetRelativeRoute(p.two,new Route("q")).Format() );
				Assert.AreEqual( "q", p.router.GetRelativeRoute(p.P0, new Route("q")).Format() );
				Assert.AreEqual( "q", p.router.GetRelativeRoute(p.TP1, new Route("q")).Format() );
				
				Assert.AreEqual( "q", p.inner.GetRelativeRoute(p.i1, new Route("q")).Format() );
				Assert.AreEqual( "i2/q", p.inner.GetRelativeRoute(p.P3, new Route("q")).Format() );
				Assert.AreEqual( "i2/q", p.inner.GetRelativeRoute(p.n1, new Route("q")).Format() );
			}
		}
		
		[Test]
		//variant of RelativeNest to ensure modify does the same thing
		public void RelativeNestModify()
		{
			Router.TestClearMasterRoute();
			var p = new UX.Router.RelativeNestModify();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "one", p.router.GetCurrentRoute().Format() );
				Assert.AreEqual( "i1", p.inner.GetCurrentRoute().Format() );
				
				p.GotoTwo.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "two", p.router.GetCurrentRoute().Format() );
				Assert.AreEqual( "i1", p.inner.GetCurrentRoute().Format() );
				
				p.GotoI2.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "two", p.router.GetCurrentRoute().Format() );
				Assert.AreEqual( "i2/n1", p.inner.GetCurrentRoute().Format() );
				
				//make inner non-current
				p.PushOne.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "one", p.router.GetCurrentRoute().Format() );
				Assert.AreEqual( "i2/n1", p.inner.GetCurrentRoute().Format() );
				
				p.GotoN2.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "one", p.router.GetCurrentRoute().Format() );
				Assert.AreEqual( "i2/n2", p.inner.GetCurrentRoute().Format() );
			}
		}
	}
}
