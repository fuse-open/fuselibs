using Uno;
using Uno.Testing;
using Uno.UX;

using FuseTest;

using Fuse.Elements;

namespace Fuse.Navigation.Test
{
	public class RouterTest : TestBase
	{
		string SafeFormat( RouterPageRoute r )
		{
			if (r == null) 
				return "*null*";
			return r.Format();
		}
		string SafeFormat( Route r )
		{
			if (r == null) 
				return "*null*";
			return r.Format();
		}
		
		[Test]
		public void Basic()
		{
			var p = new UX.RouterTest();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "two/b", p.routerA.GetCurrentRoute().Format() ); 
				Assert.AreEqual( "two/b", SafeFormat(p.routerA.GetHistoryRoute(0)) );
				Assert.AreEqual( null, p.routerA.GetHistoryRoute(1) );
				
				p.routerA.Goto( new Route("one"));
				root.StepFrame(5); //stabilse animation (it's undefined precisely when the route changes)
				Assert.AreEqual( "one/ii", SafeFormat(p.routerA.GetCurrentRoute()) ); 
				Assert.AreEqual( "one/ii", SafeFormat(p.routerA.GetHistoryRoute(0)) );
				Assert.AreEqual( null, p.routerA.GetHistoryRoute(1) );

				p.routerA.Push( new Route("one", null, new Route( "iii")));
				root.StepFrame(5);
				Assert.AreEqual( "one/iii/bee", p.routerA.GetCurrentRoute().Format() ); 
				Assert.AreEqual( "one/iii/bee", SafeFormat(p.routerA.GetHistoryRoute(0)) );
				
				p.routerA.Push( new Route("one", null, new Route( "i")));
				root.StepFrame(5);
				Assert.AreEqual( "one/i", p.routerA.GetCurrentRoute().Format() ); 
				Assert.AreEqual( "one/i", SafeFormat(p.routerA.GetHistoryRoute(0)) );
				
				p.routerA.GoBack();
				root.StepFrame(5);
				Assert.AreEqual( "one/iii/bee", p.routerA.GetCurrentRoute().Format() );
				Assert.AreEqual( "one/iii/bee", SafeFormat(p.routerA.GetHistoryRoute(0)) );
				
				p.routerA.GoBack();
				root.StepFrame(5);
				Assert.AreEqual( "one/ii", p.routerA.GetCurrentRoute().Format() );
				Assert.AreEqual( "one/ii", SafeFormat(p.routerA.GetHistoryRoute(0)) );
				
				Assert.IsFalse(p.routerA.CanGoBack);
			}
		}
		
		[Test]
		//extracted from a failure in Basic
		public void Scenario1()
		{
			var p = new UX.Router.Scenario1();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
 				Assert.AreEqual( "one/ii", SafeFormat(p.router.GetHistoryRoute(0)) );
 				Assert.AreEqual( null, p.router.GetHistoryRoute(1) );
			}
		}
		
		[Test]
		public void SelfChange()
		{
			var p = new UX.RouterTest();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "", p.routerB.GetCurrentRoute().Format() );
				
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
			var p = new UX.MasterRoute();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				p.Master.Goto( new Route( "one" ) );
				p.Master.Push( new Route( "two", "chum", new Route( "b" ) ) );
				p.Master.Push( new Route( "two", "burp", new Route( "b" ) ) );
				root.PumpDeferred();

				//Route survives destruction
				var store = root.RootViewport.SavePreviewState();
				root.Children.Remove(p);
				
				p = new UX.MasterRoute();
				root.RootViewport.RestorePreviewState(store);
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
		//https://github.com/fusetools/fuselibs-private/issues/3689
		public void RelativeNonCurrent()
		{
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
			var p = new UX.Router.RelativeNest();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "one", SafeFormat(p.router.GetCurrentRoute()) );
				Assert.AreEqual( "i1", SafeFormat(p.inner.GetCurrentRoute()) );
				
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
		
		[Test]
		public void HistoryBasic()
		{
			var p = new UX.Router.HistoryBasic();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "a", p.router.GetCurrentRoute().Format() ); 
				Assert.AreEqual( "a", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(1) );
				
				p.router.Goto( new Route("b"));
				root.StepFrame(); //actual change could be delayed a frame
				Assert.AreEqual( "b", SafeFormat(p.router.GetCurrentRoute()) ); 
				Assert.AreEqual( "b", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(1) );
				
				p.router.Push( new Route("c"));
				root.StepFrame();
				Assert.AreEqual( "c", SafeFormat(p.router.GetCurrentRoute()) ); 
				Assert.AreEqual( "c", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( "b", SafeFormat(p.router.GetHistoryRoute(1)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(2) );
				
				p.router.GoBack();
				root.StepFrame();
				Assert.AreEqual( "b", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(1) );
			}
		}
		
		[Test]
		public void HistoryMulti()
		{
			var p = new UX.Router.HistoryMulti();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "a/hot", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(1) );
				
				p.router.Push( new Route( "a", null, new Route("cold" ) ) );
				root.StepFrame();
				Assert.AreEqual( "a/cold", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( "a/hot", SafeFormat(p.router.GetHistoryRoute(1)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(2) );
				
				p.router.Push( new Route( "b", null, new Route("cat" ) ) );
				root.StepFrame();
				Assert.AreEqual( "b/cat", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( "a/cold", SafeFormat(p.router.GetHistoryRoute(1)) );
				Assert.AreEqual( "a/hot", SafeFormat(p.router.GetHistoryRoute(2)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(3) );
				
				p.router.Push( new Route( "a", null, new Route("warm" ) ) );
				root.StepFrame();
				Assert.AreEqual( "a/warm", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( "b/cat", SafeFormat(p.router.GetHistoryRoute(1)) );
				Assert.AreEqual( "a/cold", SafeFormat(p.router.GetHistoryRoute(2)) );
				Assert.AreEqual( "a/hot", SafeFormat(p.router.GetHistoryRoute(3)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(4) );

				p.router.GoBack();
				root.StepFrame();
				Assert.AreEqual( "b/cat", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( "a/cold", SafeFormat(p.router.GetHistoryRoute(1)) );
				Assert.AreEqual( "a/hot", SafeFormat(p.router.GetHistoryRoute(2)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(3) );
				
				p.router.GoBack();
				root.StepFrame();
				Assert.AreEqual( "a/cold", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( "a/hot", SafeFormat(p.router.GetHistoryRoute(1)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(2) );
			}
		}
		
		[Test]
		public void NavigatorHistoryBasic()
		{
			var p = new UX.Router.NavigatorHistoryBasic();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "", SafeFormat(p.router.GetHistoryRoute(0)) );
				
				p.router.Goto( new Route("b"));
				root.StepFrame(); //actual change could be delayed a frame
				Assert.AreEqual( "b", SafeFormat(p.router.GetCurrentRoute()) ); 
				Assert.AreEqual( "b", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(1) );
				
				p.router.Push( new Route("c"));
				root.StepFrame();
				Assert.AreEqual( "c", SafeFormat(p.router.GetCurrentRoute()) ); 
				Assert.AreEqual( "c", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( "b", SafeFormat(p.router.GetHistoryRoute(1)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(2) );
				
				p.router.GoBack();
				root.StepFrame();
				Assert.AreEqual( "b", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(1) );
			}
		}

		[Test]
		public void NavigatorHistoryMulti()
		{
			var p = new UX.Router.NavigatorHistoryMulti();
			using (var root = TestRootPanel.CreateWithChild(p))
			{	
				root.MultiStepFrame(5);
				Assert.AreEqual( "a/hot", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(1) );
				
				p.router.Push( new Route( "a", null, new Route("cold" ) ) );
				root.MultiStepFrame(5);
				Assert.AreEqual( "a/cold", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( "a/hot", SafeFormat(p.router.GetHistoryRoute(1)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(2) );
				
				p.router.Push( new Route( "b", null, new Route("cat" ) ) );
				root.StepFrame();
				Assert.AreEqual( "b/cat", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( "a/cold", SafeFormat(p.router.GetHistoryRoute(1)) );
				Assert.AreEqual( "a/hot", SafeFormat(p.router.GetHistoryRoute(2)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(3) );
				
				p.router.Push( new Route( "a", null, new Route("warm" ) ) );
				root.StepFrame();
				Assert.AreEqual( "a/warm", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( "b/cat", SafeFormat(p.router.GetHistoryRoute(1)) );
				Assert.AreEqual( "a/cold", SafeFormat(p.router.GetHistoryRoute(2)) );
				Assert.AreEqual( "a/hot", SafeFormat(p.router.GetHistoryRoute(3)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(4) );

				p.router.GoBack();
				root.StepFrame();
				Assert.AreEqual( "b/cat", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( "a/cold", SafeFormat(p.router.GetHistoryRoute(1)) );
				Assert.AreEqual( "a/hot", SafeFormat(p.router.GetHistoryRoute(2)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(3) );
				
				p.router.GoBack();
				root.StepFrame();
				Assert.AreEqual( "a/cold", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( "a/hot", SafeFormat(p.router.GetHistoryRoute(1)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(2) );
			}
		}
		
		[Test]
		public void HistoryActiveIndex()
		{
			var p = new UX.Router.HistoryActiveIndex();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "A", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(1) );
				
				p.Goto2.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "C", SafeFormat(p.router.GetHistoryRoute(0)) );
				
				p.Goto4.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "E", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(1) );
			}
		}

		[Test]
		public void HistoryParameter()
		{
			var p = new UX.Router.HistoryParameter();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "a", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(1) );
				
				p.router.Push( new Route("a", "1"));
				root.StepFrame(); //actual change could be delayed a frame
				Assert.AreEqual( "a?1", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( "a", SafeFormat(p.router.GetHistoryRoute(1)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(2) );
				
				p.router.Push( new Route("a", "2"));
				root.StepFrame();
				Assert.AreEqual( "a?2", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( "a?1", SafeFormat(p.router.GetHistoryRoute(1)) );
				Assert.AreEqual( "a", SafeFormat(p.router.GetHistoryRoute(2)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(3) );

				p.router.GoBack();
				root.StepFrame();
				Assert.AreEqual( "a?1", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( "a", SafeFormat(p.router.GetHistoryRoute(1)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(2) );

				p.router.GoBack();
				root.StepFrame();
				Assert.AreEqual( "a", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(1) );
			}
		}
		
		[Test]
		public void NavigatorHistoryParameter()
		{
			var p = new UX.Router.NavigatorHistoryParameter();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "one/bird", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(1) );
				
				p.callPushBird.Perform();
				root.StepFrameJS();
				root.StepFrame(5); //stabilize animation
				Assert.AreEqual( "one?{}/bird?{\"id\":1}", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( "one/bird", SafeFormat(p.router.GetHistoryRoute(1)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(2) );
				
				p.callPushBird.Perform();
				root.StepFrameJS();
				root.StepFrame(5); //stabilize animation
				Assert.AreEqual( "one?{}/bird?{\"id\":2}", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( "one?{}/bird?{\"id\":1}", SafeFormat(p.router.GetHistoryRoute(1)) );
				Assert.AreEqual( "one/bird", SafeFormat(p.router.GetHistoryRoute(2)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(3) );

				p.callGoBack.Perform();
				root.StepFrameJS();
				root.StepFrame(5);
				Assert.AreEqual( "one?{}/bird?{\"id\":1}", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( "one/bird", SafeFormat(p.router.GetHistoryRoute(1)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(2) );

				p.callGoBack.Perform();
				root.StepFrameJS();
				root.StepFrame(5);
				Assert.AreEqual( "one/bird", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(1) );
			}
		}

		[Test]
		public void HistorySame()
		{
			var p = new UX.Router.HistorySame();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				p.router.Push( new Route("a") );
				root.StepFrame();
				Assert.AreEqual( "a", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( "a", SafeFormat(p.router.GetHistoryRoute(1)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(2) );

				p.router.Goto( new Route( "b", null, new Route("i" )) );
				root.StepFrame();
				p.router.Push( new Route( "b", null, new Route("i" )) );
				root.StepFrame();
				p.router.Push( new Route( "b", null, new Route("ii" )) );
				root.StepFrame();
				p.router.Push( new Route( "a" ) );
				root.StepFrame();
				p.router.Push( new Route( "a" ) );
				root.StepFrame();
				p.router.Push( new Route( "c" ) );
				root.StepFrame();
				p.router.Push( new Route( "b", null, new Route("ii" )) );
				root.StepFrame();
				p.router.Push( new Route( "b", null, new Route("ii" )) );
				root.StepFrame();
				p.router.Push( new Route( "b", null, new Route("ii" )) );
				root.StepFrame();
				Assert.AreEqual( "b/ii", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( "b/ii", SafeFormat(p.router.GetHistoryRoute(1)) );
				Assert.AreEqual( "b/ii", SafeFormat(p.router.GetHistoryRoute(2)) );
				Assert.AreEqual( "c", SafeFormat(p.router.GetHistoryRoute(3)) );
				Assert.AreEqual( "a", SafeFormat(p.router.GetHistoryRoute(4)) );
				Assert.AreEqual( "a", SafeFormat(p.router.GetHistoryRoute(5)) );
				Assert.AreEqual( "b/ii", SafeFormat(p.router.GetHistoryRoute(6)) );
				Assert.AreEqual( "b/i", SafeFormat(p.router.GetHistoryRoute(7)) );
				Assert.AreEqual( "b/i", SafeFormat(p.router.GetHistoryRoute(8)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(9) );
			}
		}
		
		[Test]
		public void ObservableGoBack()
		{
			var p = new UX.Router.ObservableGoBack();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual( 0, p.wc.Progress );
				Assert.AreEqual( "1", GetText(p.nav.Active) );
				Assert.AreEqual( "1", p.history.Value );
				
				p.callPush.Perform();
				root.StepFrameJS();
				Assert.AreEqual( 1, p.wc.Progress );
				Assert.AreEqual( "2", GetText(p.nav.Active) );
				Assert.AreEqual( "1,2", p.history.Value );

				//several calls to build up history and have navigator reuse the pages
				p.callPush.Perform(); //3
				root.StepFrameJS();
				p.callPush.Perform(); //4
				root.StepFrameJS();
				p.callPush.Perform(); //5
				root.StepFrameJS();
				Assert.AreEqual( 1, p.wc.Progress );
				Assert.AreEqual( "5", GetText(p.nav.Active) );
				Assert.AreEqual( "1,2,3,4,5", p.history.Value );
				
				p.goBack.Pulse();
				root.StepFrameJS();
				Assert.AreEqual( 1, p.wc.Progress );
				Assert.AreEqual( "4", GetText(p.nav.Active) );
				Assert.AreEqual( "1,2,3,4", p.history.Value );
				
				p.goBack.Pulse();
				root.StepFrameJS();
				Assert.AreEqual( 1, p.wc.Progress );
				Assert.AreEqual( "3", GetText(p.nav.Active) );
				Assert.AreEqual( "1,2,3", p.history.Value );
			}
		}
		
		[Test]
		public void ObjectPath()
		{
			var p = new UX.Router.ObjectPath();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				
				p.callGoto.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "5", GetText(p.nav.Active));
				
				p.push.Pulse();
				root.StepFrame();
				Assert.AreEqual( "!6,2.happy", GetRecursiveText(p.nav.Active));
			
				((ROPTwo)p.nav.Active).callPushRelative.Perform();
				root.StepFrameJS();
				root.StepFrame(5); //finish animation
				Assert.AreEqual( "!6,1.joyous", GetRecursiveText(p.nav.Active));
				
				p.router.GoBack();
				root.StepFrame(5);
				Assert.AreEqual( "!6,2.happy", GetRecursiveText(p.nav.Active));
				
				p.router.GoBack();
				root.StepFrame();
				Assert.AreEqual( "5", GetText(p.nav.Active));
			}
		}
		
		[Test]
		public void ModifyObject()
		{
			var p = new UX.Router.ModifyObject();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				p.gotoR.Pulse();
				root.StepFrameJS();
				Assert.AreEqual( "5", GetText(p.nav.Active));
				
				p.pushSecond.Pulse();
				root.StepFrame(5); //complete animation
				Assert.AreEqual( "!6,2.happy", GetRecursiveText(p.nav.Active));
				
				p.pushFirst.Pulse();
				root.StepFrameJS();
				root.StepFrame(5);
				Assert.AreEqual( "!7,1.joyous", GetRecursiveText(p.nav.Active));
				
				p.router.GoBack();
				root.StepFrame(5);
				Assert.AreEqual( "!6,2.happy", GetRecursiveText(p.nav.Active));
				
				p.pushFirstBits.Pulse();
				root.StepFrameJS();
				root.StepFrame(5);
				Assert.AreEqual( "!7,1.joyous", GetRecursiveText(p.nav.Active));
				
				p.pushThird.Pulse();
				root.StepFrameJS();
				root.StepFrame(5);
				Assert.AreEqual( "?9,ii.bub", GetRecursiveText(p.nav.Active));
			}
		}
		
		[Test]
		//Based on https://github.com/fuse-open/fuselibs/issues/939
		public void DoublePushGoBack()
		{
			var p = new UX.Router.DoublePushGoBack();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual( "one", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(1) );
				
				p.callPush.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "two?{}", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( "two?{}", SafeFormat(p.router.GetHistoryRoute(1)) );
				Assert.AreEqual( "one", SafeFormat(p.router.GetHistoryRoute(2)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(3) );
				
				p.callGoBack.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "two?{}", SafeFormat(p.router.GetHistoryRoute(0)) );
				Assert.AreEqual( "one", SafeFormat(p.router.GetHistoryRoute(1)) );
				Assert.AreEqual( null, p.router.GetHistoryRoute(2) );
			}
		}
		
		[Test]
		//Crash in https://github.com/fuse-open/fuselibs/issues/1066
		public void Issue1066()
		{
			var p = new UX.Router.Issue1066();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				p.router.GoBack();
				p.router.GoBack(); //shouldn't crash
			}
		}
		
	}
}
	