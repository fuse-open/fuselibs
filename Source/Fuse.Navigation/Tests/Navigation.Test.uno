using Uno;
using Uno.Compiler;
using Uno.Testing;
using Uno.UX;

using FuseTest;

using Fuse.Controls;
using Fuse.Elements;

namespace Fuse.Navigation.Test
{
	public class NavigationTest : TestBase
	{
		//BackButton

		[Test]
		public void BackButtonAllElementPropertyTests()
		{
			var b = new BackButton();
			ElementPropertyTester.All(b);
		}

		[Test]
		public void BackButtonAllLayoutTests()
		{
			var b = new BackButton();
			ElementLayoutTester.All(b);
		}

		//NavigationBar

		[Test]
		public void NavigationBarAllElementPropertyTests()
		{
			var n = new NavigationBar();
			ElementPropertyTester.All(n);
		}

		[Test]
		public void NavigationBarAllElementLayoutTests()
		{
			var n = new NavigationBar();
			ElementLayoutTester.All(n);
		}

		[Test]
		public void JSGetRoute()
		{
			Assert.AreEqual(0, Fuse.Triggers.TransitionGroup.TestMemoryCount );

			var p = new UX.JSGetRoute();
			using (var root = TestRootPanel.CreateWithChild(p, int2(100)))
			{
				root.MultiStepFrameJS(2);

				p.CallStepTwo.Perform();
				root.MultiStepFrameJS(2);

				// If no exceptions we're good.
				Assert.AreEqual( "yes", p.done.Value );
			}

			Assert.AreEqual(0, Fuse.Triggers.TransitionGroup.TestMemoryCount );
		}

		[Test]
		/*
			Tests the locators for pages and navigation in a variety of nesting scenarios.
		*/
		public void TryFindPage()
		{
			var p = new UX.NavigationLocator();
			using (var root = TestRootPanel.CreateWithChild(p, int2(100)))
			{
				TFPCheck(root, p.P1, p.Inner1, p.P1, null);
				TFPCheck(root, p.E1, p.Inner1, p.P1, null);
				TFPCheck(root, p.P2, p.Outer, p.P2, null);
				TFPCheck(root, p.E2, p.Outer, p.P2, null);
				TFPCheck(root, p.E3, p.Outer, p.P2, p.E3);
				TFPCheck(root, p.E4, p.Outer, p.P2, p.E3);

				TFPCheck(root, p.DP1, p.Deep1, p.DP1, null);
				TFPCheck(root, p.P4, p.Inner2, p.P4, null);
			}
		}

		void TFPCheck(TestRootPanel root, Visual page, INavigation navObject, Visual pageObject, Visual pageBindObject,
			[CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0,
			[CallerMemberName] string memberName = "")
		{
			_navReady = false;
			var npp  = new NavigationPageProxy();
			npp.Init(NavReady, NavUnready,page);

			Assert.IsTrue(_navReady);
			Assert.AreEqual(navObject, npp.Navigation, filePath, lineNumber, memberName + ": NavObject");
			Assert.AreEqual(pageObject, npp.Page, filePath, lineNumber, memberName + ": PageObject");
			Assert.AreEqual(pageBindObject, npp.PageBind, filePath, lineNumber, memberName + ": PageBindObject");

			npp.Dispose();
			Assert.IsFalse(_navReady);
		}

		bool _navReady;
		void NavReady(object s)
		{
			_navReady = true;
		}

		void NavUnready(object s)
		{
			_navReady = false;
		}

		[Test]
		/*
			https://github.com/fusetools/fuselibs-private/issues/1804
			Ensure changed messages aren't published needlessly
		*/
		public void Stability()
		{
			var p = new UX.Stability();
			using (var root = TestRootPanel.CreateWithChild(p, int2(100)))
			{
				p.TheNav.PageProgressChanged += OnPageProgressChanged;
				_changeCount = 0;
				p.TheNav.Active = p.P2;
				root.IncrementFrame();
				Assert.AreEqual(1, _changeCount); //expect update on first frame
				root.IncrementFrame();
				Assert.AreEqual(2, _changeCount);
				//allow to reach end
				root.StepFrame(1);
				_changeCount = 0;
				root.IncrementFrame();
				Assert.AreEqual(0, _changeCount);
			}
		}

		int _changeCount;
		void OnPageProgressChanged(object sender, NavigationArgs args)
		{
			_changeCount++;
		}

		[Test]
		public void PageBinding()
		{
			var p = new UX.PageBinding();
			using (var root = TestRootPanel.CreateWithChild(p,int2(100)))
			{
				Assert.AreEqual("One", p.T1.Value);
				Assert.AreEqual("Three", p.T2.Value);

				Assert.AreEqual(3, p.I1.Children.Count);
				Assert.AreEqual(20, (p.I1.Children[0] as Element).Width.Value);
				Assert.AreEqual(10, (p.I1.Children[1] as Element).Width.Value);

				Assert.AreEqual(3, p.I2.Children.Count);
				Assert.AreEqual(20, (p.I2.Children[0] as Element).Width.Value);
				Assert.AreEqual(10, (p.I2.Children[1] as Element).Width.Value);

				p.Outer.Goto(p.P2, NavigationGotoMode.Bypass);
				root.IncrementFrame();

				Assert.AreEqual("Two", p.T1.Value);
				Assert.AreEqual("Three", p.T2.Value);

				Assert.AreEqual(10, (p.I1.Children[0] as Element).Width.Value);
				Assert.AreEqual(20, (p.I1.Children[1] as Element).Width.Value);

				Assert.AreEqual(10, (p.I2.Children[0] as Element).Width.Value);
				Assert.AreEqual(20, (p.I2.Children[1] as Element).Width.Value);

				//allow transition animation
				p.Outer.Active = p.P1;
				root.StepFrame(1.1f);

				Assert.AreEqual("One", p.T1.Value);
				Assert.AreEqual("Three", p.T2.Value);

				Assert.AreEqual(20, (p.I1.Children[0] as Element).Width.Value);
				Assert.AreEqual(10, (p.I1.Children[1] as Element).Width.Value);

				Assert.AreEqual(20, (p.I2.Children[0] as Element).Width.Value);
				Assert.AreEqual(10, (p.I2.Children[1] as Element).Width.Value);
			}
		}

		[Test]
		//tests the use-cases intended to be fulfilled by page bindings, including the PageIndicator
		public void PageBindingFull()
		{
			var p = new UX.PageBindingFull();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual("one", p.ActiveTitle.Value);
				Assert.AreEqual(float4(1,0,0,1), p.ActiveTitle.Color);

				var p1 = p.PI.GetZOrderChild(2) as PBFDot;
				Assert.AreEqual("one", p1.T.Value );
				Assert.AreEqual(float4(1,0,0,1), p1.T.Color);
				Assert.AreEqual(1,TriggerProgress(p1.WA));
				var p2 = p.PI.GetZOrderChild(1) as PBFDot;
				Assert.AreEqual("two", p2.T.Value );
				Assert.AreEqual(float4(0,1,0,1), p2.T.Color);
				Assert.AreEqual(0,TriggerProgress(p2.WA));
				var p3 = p.PI.GetZOrderChild(0) as PBFDot;
				Assert.AreEqual("three", p3.T.Value );
				Assert.AreEqual(float4(0,0,1,1), p3.T.Color);
				Assert.AreEqual(0,TriggerProgress(p3.WA));

				p.mainNav.Active = p.P3;
				root.StepFrame(5); //stabilize animations

				Assert.AreEqual("three", p.ActiveTitle.Value);
				Assert.AreEqual(float4(0,0,1,1), p.ActiveTitle.Color);

				Assert.AreEqual(0,TriggerProgress(p1.WA));
				Assert.AreEqual(0,TriggerProgress(p2.WA));
				Assert.AreEqual(1,TriggerProgress(p3.WA));
			}
		}

		[Test]
		/* Even if we remove HierNav somehow keep this function for PageIndicator. It tests
			whether dynamically added pages in navigation are being bound correctly.

			The need for multiple triggers here is to track down some defects with the lists
			in the bindings -- in demos only some of the triggers were updating correctly.
		*/
		public void HierNavBinding()
		{
			var p = new UX.HierNavBinding();
			using (var root = TestRootPanel.CreateWithChild(p,int2(100)))
			{
				Assert.AreEqual(1, p.I2.Children.Count);
				Assert.AreEqual(20, (p.I2.Children[0] as Element).Width.Value);
				Assert.AreEqual(10, (p.I2.Children[0] as Element).Height.Value);
				Assert.AreEqual(10, (p.I2.Children[0] as Element).X.Value);

				p.Outer.Goto(p.P2,NavigationGotoMode.Bypass);
				root.IncrementFrame();

				Assert.AreEqual(2, p.I2.Children.Count);
				Assert.AreEqual(20, (p.I2.Children[0] as Element).Width.Value); //new pages added on top
				Assert.AreEqual(10, (p.I2.Children[0] as Element).Height.Value);
				Assert.AreEqual(10, (p.I2.Children[0] as Element).X.Value);

				Assert.AreEqual(10, (p.I2.Children[1] as Element).Width.Value);
				Assert.AreEqual(10, (p.I2.Children[1] as Element).Height.Value);
				Assert.AreEqual(20, (p.I2.Children[1] as Element).X.Value);

				p.Outer.Goto(p.P3,NavigationGotoMode.Bypass);
				root.IncrementFrame();

				Assert.AreEqual(3, p.I2.Children.Count);
				Assert.AreEqual(20, (p.I2.Children[0] as Element).Width.Value); //new pages added on top

				Assert.AreEqual(10, (p.I2.Children[1] as Element).Width.Value);
				Assert.AreEqual(10, (p.I2.Children[1] as Element).Height.Value);
				Assert.AreEqual(20, (p.I2.Children[1] as Element).X.Value);

				Assert.AreEqual(10, (p.I2.Children[2] as Element).Width.Value);

				//center on page to get enter/exit states
				p.Outer.Goto(p.P2,NavigationGotoMode.Bypass);
				Assert.AreEqual(3, p.I2.Children.Count);
				Assert.AreEqual(10, (p.I2.Children[0] as Element).Width.Value);
				Assert.AreEqual(20, (p.I2.Children[0] as Element).Height.Value);
				Assert.AreEqual(10, (p.I2.Children[0] as Element).X.Value);

				Assert.AreEqual(20, (p.I2.Children[1] as Element).Width.Value);
				Assert.AreEqual(10, (p.I2.Children[1] as Element).Height.Value);
				Assert.AreEqual(10, (p.I2.Children[1] as Element).X.Value);

				Assert.AreEqual(10, (p.I2.Children[2] as Element).Width.Value);
				Assert.AreEqual(10, (p.I2.Children[2] as Element).Height.Value);
				Assert.AreEqual(20, (p.I2.Children[2] as Element).X.Value);
			}
		}

		[Test]
		//https://github.com/fusetools/fuselibs-private/issues/3761
		public void RootScale()
		{
			var p = new UX.Navigation.Scale();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(0, TriggerProgress(p.P1.X));
				Assert.AreEqual(0.1f, TriggerProgress(p.P2.X));
				Assert.AreEqual(0.2f, TriggerProgress(p.P3.X));
				Assert.AreEqual(0.3f, TriggerProgress(p.P4.X));

				Assert.AreEqual(0, TriggerProgress(p.P1.N));
				Assert.AreEqual(0, TriggerProgress(p.P2.N));
				Assert.AreEqual(0, TriggerProgress(p.P3.N));
				Assert.AreEqual(0, TriggerProgress(p.P4.N));

				Assert.AreEqual(1, TriggerProgress(p.P1.A));
				Assert.AreEqual(0.4f, TriggerProgress(p.P2.A));
				Assert.AreEqual(0, TriggerProgress(p.P3.A));
				Assert.AreEqual(0, TriggerProgress(p.P4.A));

				Assert.AreEqual(0, TriggerProgress(p.P1.D));
				Assert.AreEqual(0.25f, TriggerProgress(p.P2.D));
				Assert.AreEqual(0.50f, TriggerProgress(p.P3.D));
				Assert.AreEqual(0.75f, TriggerProgress(p.P4.D));


				p.Nav.Active=p.P3;
				root.StepFrame(5);

				for (int i=0; i < 2; ++i)
				{
					Assert.AreEqual(0, TriggerProgress(p.P1.X));
					Assert.AreEqual(0, TriggerProgress(p.P2.X));
					Assert.AreEqual(0, TriggerProgress(p.P3.X));
					Assert.AreEqual(0.1f, TriggerProgress(p.P4.X));

					Assert.AreEqual(1, TriggerProgress(p.P1.N));
					Assert.AreEqual(0.5f, TriggerProgress(p.P2.N));
					Assert.AreEqual(0, TriggerProgress(p.P3.N));
					Assert.AreEqual(0, TriggerProgress(p.P4.N));

					Assert.AreEqual(0, TriggerProgress(p.P1.A));
					Assert.AreEqual(0.4f, TriggerProgress(p.P2.A));
					Assert.AreEqual(1, TriggerProgress(p.P3.A));
					Assert.AreEqual(0.4f, TriggerProgress(p.P4.A));

					Assert.AreEqual(0.50f, TriggerProgress(p.P1.D));
					Assert.AreEqual(0.25f, TriggerProgress(p.P2.D));
					Assert.AreEqual(0.00f, TriggerProgress(p.P3.D));
					Assert.AreEqual(0.25f, TriggerProgress(p.P4.D));

					//ensure consistent over unroot/root
					p.Children.Remove(p.C);
					root.StepFrame();
					p.Children.Add(p.C);
					root.PumpDeferred();
				}
			}
		}

	}
}
