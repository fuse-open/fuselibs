using Uno;
using Uno.Collections;
using Uno.Compiler;
using Fuse;
using FuseTest;
using Fuse.Controls;
using Fuse.Elements;
using Fuse.Resources;
using Uno.Testing;
using Uno.Graphics;
using Fuse.Layouts;

namespace Fuse.Controls.Test
{
	public class DockPanelTest : TestBase
	{
		public class DummyElement : Element
		{
			protected override void OnDraw(Fuse.DrawContext dc) { }
		}

		[Test]
		public void AllPanelProps()
		{
			var s = new DockPanel();
			PanelTester.AllSimpleTests(s);
		}

		[Test]
		public void AllPanelLayout()
		{
			var s = new DockPanel();
			PanelTester.AllLayoutTests(s);
		}

		[Test]
		public void SetDock_1()
		{
			var e = new DummyElement();
			DockPanel.SetDock(e, Dock.Left);
			Assert.AreEqual(Dock.Left, DockPanel.GetDock(e));
		}

		[Test]
		public void SetDock_2()
		{
			var e = new DummyElement();
			DockPanel.SetDock(e, Dock.Right);
			Assert.AreEqual(Dock.Right, DockPanel.GetDock(e));
		}

		[Test]
		public void ResetDock()
		{
			var e = new DummyElement();
			var dock = DockPanel.GetDock(e);
			DockPanel.SetDock(e, Dock.Top);
			Assert.AreEqual(Dock.Top, DockPanel.GetDock(e));
			DockPanel.ResetDock(e);
			Assert.AreEqual(dock, DockPanel.GetDock(e));
		}

		[Test]
		public void AllElementProps()
		{
			var d = new DockPanel();
			ElementPropertyTester.All(d);
		}

		[Test]
		public void AllElementLayoutTests()
		{
			var d = new DockPanel();
			ElementLayoutTester.All(d);
		}

		[Test]
		public void DockAlignmentOnePanel()
		{
			var parent = new DockPanel();

			var child = new Panel();
			parent.Children.Add(child);
			child.Width = 10;
			child.Height = 10;

			using (var root = TestRootPanel.CreateWithChild(parent))
			{
				child.Margin = float4(5, 2, 7, 1);
				TestElementDockLayout(root, child, Dock.Fill,
					int2(700, 1000), float2(10, 10), float2((700-10-7+5)/2, (1000-10-1+2)/2f));
				TestElementDockLayout(root, child, Dock.Fill, int2(1900, 800), float2(10, 10), float2((1900-10-7+5)/2, (800-10-1+2)/2f));
				TestElementDockLayout(root, child, Dock.Fill, int2(1300, 1300), float2(10, 10), float2((1300-10-7+5)/2, (1300-10-1+2)/2f));
				TestElementDockLayout(root, child, Dock.Fill, int2(50, 20), float2(10, 10), float2((50-10-7+5)/2, (20-10-1+2)/2f));

				child.Margin = float4(1, 2, 3, 4);
				TestElementDockLayout(root, child, Dock.Left, int2(400, 300), float2(10, 10), float2(1, (300-10-4+2)/2));
				TestElementDockLayout(root, child, Dock.Right, int2(550, 200), float2(10, 10), float2(550-3-10, (200-10-4+2)/2));
				TestElementDockLayout(root, child, Dock.Top, int2(700, 500), float2(10, 10), float2((700-10-3+1)/2, 2));
				TestElementDockLayout(root, child, Dock.Bottom, int2(200, 100), float2(10, 10), float2((200-10-3+1)/2, 100-10-4));
			}
		}

		[Test]
		public void DockAlignmentTwoPanel()
		{
			var parent = new DockPanel();

			var child1 = new Panel();
			child1.Margin = float4(10, 5, 20, 15);
			child1.Height = 50;
			parent.Children.Add(child1);

			var child2 = new Panel();
			child2.Margin = float4(10, 5, 20, 15);
			child2.Height = 200;
			parent.Children.Add(child2);

			using (var root = TestRootPanel.CreateWithChild(parent))
			{
				TestElementDockLayout(root, child1, Dock.Bottom, int2(500, 600), float2(500-10-20, 50), float2(10, 600-50-15));
				TestElementDockLayout(root, child2, Dock.Fill, int2(500, 600), float2(500-10-20, 200), float2(10, (600-50-15-5 - 200-15+5)/2));

				child1.Width = 100;
				child2.Width = 300;

				TestElementDockLayout(root, child1, Dock.Right, int2(1024, 768), float2(100, 50), float2(1024-100-20, (768-50-15+5)/2));
				TestElementDockLayout(root, child2, Dock.Fill, int2(1024, 768), float2(300, 200), float2((1024 - 10-100-20 - 300-20+10)/2, (768-200-15+5)/2));

				TestElementDockLayout(root, child1, Dock.Left, int2(320, 240), float2(100, 50), float2(10, (240-50-15+5)/2));
				TestElementDockLayout(root, child2, Dock.Fill, int2(320, 240), float2(300, 200),
					float2(70, (240-200-15+5)/2));

				TestElementDockLayout(root, child1, Dock.Left, int2(1234, 789), float2(100, 50), float2(10, (789-50-15+5)/2f));
				TestElementDockLayout(root, child2, Dock.Fill, int2(1234, 789), float2(300, 200), float2(10+100+20 + (1234 - 10-100-20 - 300-20+10)/2, (789-200-15+5)/2f));
			}
		}

		[Test]
		public void DockAlignmentThreePanel()
		{
			var parent = new DockPanel();

			var child1 = new Panel();
			child1.Margin = float4(7, 18, 22, 1);
			child1.Height = 92;
			parent.Children.Add(child1);

			var child2 = new Panel();
			child2.Margin = float4(8, 3, 3, 6);
			child2.Width = 77;
			parent.Children.Add(child2);

			var child3 = new Panel();
			child3.Margin = float4(11, 7, 4, 4);
			child3.Width = 41;
			parent.Children.Add(child3);

			using (var root = TestRootPanel.CreateWithChild(parent))
			{
				TestElementDockLayout(root, child1, Dock.Right, int2(881, 672), float2(0, 92), float2(881-22, (672-92-1+18)/2f));
				TestElementDockLayout(root, child2, Dock.Left, int2(881, 672), float2(77, 672-3-6), float2(8, 3));
				TestElementDockLayout(root, child3, Dock.Fill, int2(881, 672), float2(41, 672-7-4), float2((881 + 77+8+3 - 7-22 -41-4+11)/2f, 7));
			}
		}

		[Test]
		public void DockAlignmentFourPanel()
		{
			var parent = new DockPanel();

			var child1 = new Panel();
			child1.Margin = float4(9, 3, 17, 4);
			child1.Height = 27;
			parent.Children.Add(child1);

			var child2 = new Panel();
			child2.Margin = float4(16, 4, 4, 1);
			child2.Height = 150;
			parent.Children.Add(child2);

			var child3 = new Panel();
			child3.Margin = float4(7, 8, 0, 9);
			child3.Width = 92;
			parent.Children.Add(child3);

			var child4 = new Panel();
			child4.Margin = float4(7, 7, 21, 1);
			child4.Height = 107;
			parent.Children.Add(child4);

			using (var root = TestRootPanel.CreateWithChild(parent))
			{
				TestElementDockLayout(root, child1, Dock.Top, int2(612, 421), float2(612-9-17, 27), float2(9, 3));
				TestElementDockLayout(root, child2, Dock.Right, int2(612, 421), float2(0, 150), float2(612-4, (421 + 27+3+4 - 150+4-1)/2f));
				TestElementDockLayout(root, child3, Dock.Top, int2(612, 421), float2(92, 0), float2((612-92-0+7 - 16-4)/2f, 27+3+4+8));
				TestElementDockLayout(root, child4, Dock.Fill, int2(612, 421), float2(612-16-4-7-21, 107), float2(7, (421 - 27-3-4)/2f - 7-1));
			}
		}

		[Test]
		public void DockAlignmentImageTest()
		{
			var p = new UX.DockPanel.AlignmentImage();
			using (var root = TestRootPanel.CreateWithChild(p, int2(736, 1038)))
			{
				LayoutTestHelper.TestElementLayout(p.child1, float2(736, 441), float2(0, 0), 0.0001f);
				LayoutTestHelper.TestElementLayout(p.child2, float2(46, 109), float2(736-46, 441 + (1038-441-109)/2f), 0.0001f);
			}
		}

		[Test]
		public void DockMultiFill()
		{
			var p = new UX.DockPanel.MultiFill();
			using (var root = TestRootPanel.CreateWithChild(p, int2(1000, 1000)))
			{
				Assert.AreEqual( float2(50,50), p.TheStar.ActualSize );
				Assert.AreEqual( float2(10,10), p.TheStar.ActualPosition );
				Assert.AreEqual( float2(50,50), p.ThePanel.ActualSize );
				Assert.AreEqual( float2(10,10), p.ThePanel.ActualPosition );
			}
		}

		[Test]
		public void DockRelative()
		{
			var p = new UX.DockPanel.Relative();
			using (var root = TestRootPanel.CreateWithChild(p, int2(1000, 500)))
			{
				Assert.AreEqual(float2(1000,50),p.P1.ActualSize);
				Assert.AreEqual(float2(1000,100),p.P2.ActualSize);
				Assert.AreEqual(float2(100,350),p.P3.ActualSize);
				Assert.AreEqual(float2(50,350),p.P4.ActualSize);
				Assert.AreEqual(float2(50,350),p.P5.ActualSize);
				Assert.AreEqual(float2(300,100),p.P6.ActualSize);
				Assert.AreEqual(float2(240,70),p.P7.ActualSize);
			}
		}

		[Test]
		public void DockRelativeStack()
		{
			var p = new UX.DockPanel.RelativeStack();
			using (var root = TestRootPanel.CreateWithChild(p, int2(1000, 500)))
			{
				Assert.AreEqual(float2(990,100),p.P1.ActualSize); //this is odd, but at the moment 100 is the expected heighg
				Assert.AreEqual(float2(5,395),p.P1.ActualPosition);

				Assert.AreEqual(float2(160,80),p.P2.ActualSize);
				Assert.AreEqual(float2(10,10),p.P2.ActualPosition);
			}
		}

		[Test]
		public void Max()
		{
			var p = new UX.DockPanel.Max();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000)))
			{
				Assert.AreEqual( float2(50,100), p.a1.ActualSize );
				Assert.AreEqual( float2(50,120), p.d1.ActualSize );

				Assert.AreEqual( float2(100,50), p.a2.ActualSize );
				Assert.AreEqual( float2(120,50), p.d2.ActualSize );
			}
		}

		[Test]
		public void Issue1082()
		{
			var p = new UX.DockPanel.Issue1082();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(0,p.ip.GetContentSizeCount);
			}
		}

		[Test]
		//checks source of https://github.com/fuse-open/fuselibs/issues/833
		public void RelativeSize()
		{
			var p = new UX.DockPanel.RelativeSize();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000)))
			{
				Assert.AreEqual(float2(80,400),p.left.ActualSize);
				Assert.AreEqual(float2(0,0),p.left.ActualPosition);
				Assert.AreEqual(float2(80,400),p.right.ActualSize);
				Assert.AreEqual(float2(320,0),p.right.ActualPosition);

				p.dp.Width = 200;
				root.StepFrame();
				Assert.AreEqual(float2(40,400),p.left.ActualSize);
				Assert.AreEqual(float2(0,0),p.left.ActualPosition);
				Assert.AreEqual(float2(40,400),p.right.ActualSize);
				Assert.AreEqual(float2(160,0),p.right.ActualPosition);
			}
		}


		private void TestElementDockLayout(TestRootPanel root, Element element, Fuse.Layouts.Dock dock,
			int2 rootSize, float2 expectActualSize, float2 expectActualPosition,
			[CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0, [CallerMemberName] string memberName = "" )
		{
			DockPanel.SetDock(element, dock);
			root.Layout(rootSize);
			Assert.AreEqual(expectActualSize, element.ActualSize, Assert.ZeroTolerance,
				filePath, lineNumber, memberName );
			Assert.AreEqual(expectActualPosition, element.ActualPosition, Assert.ZeroTolerance,
				filePath, lineNumber, memberName);
		}
	}

}
