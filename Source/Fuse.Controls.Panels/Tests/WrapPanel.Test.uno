using Uno;
using Uno.Collections;
using Uno.Testing;

using FuseTest;
using Fuse.Controls;
using Fuse.Elements;
using Fuse.Layouts;
using Fuse.Resources;

namespace Fuse.Controls.Panels.Test
{
	public class WrapPanelTest : TestBase
	{
		public class DummyElement : Element
		{
			protected override void OnDraw(Fuse.DrawContext dc) { }

			public DummyElement() { }

			public DummyElement(float2 minSize)
			{
				MinWidth = minSize.X;
				MinHeight = minSize.Y;
			}
		}

		public class ElementTest
		{
			public readonly Element Element;
			public readonly float2 ExpectedPos;
			public readonly float2 ExpectedSize;

			public ElementTest(Element e, float2 expectedPos, float2 expectedSize)
			{
				Element = e;
				ExpectedPos = expectedPos;
				ExpectedSize = expectedSize;
			}
		}

		[Test]
		public void AllPanelProps()
		{
			var s = new WrapPanel();
			PanelTester.AllSimpleTests(s);
		}

		[Test]
		public void AllPanelLayout()
		{
			var s = new WrapPanel();
			PanelTester.AllLayoutTests(s);
		}

		[Test]
		public void ItemSizeTest()
		{
			var wp = CreateWPWithElements(11, float2(20,40));
			using (var root = TestRootPanel.CreateWithChild(wp, int2(100)))
			{
				List<ElementTest> tests = new List<ElementTest>();
				tests.Add(new ElementTest(wp.Children[0] as Element,  float2(20,40), float2(0, 0)));
				tests.Add(new ElementTest(wp.Children[1] as Element,  float2(20,40), float2(20, 0)));
				tests.Add(new ElementTest(wp.Children[2] as Element,  float2(20,40), float2(40, 0)));
				tests.Add(new ElementTest(wp.Children[3] as Element,  float2(20,40), float2(60, 0)));
				tests.Add(new ElementTest(wp.Children[4] as Element,  float2(20,40), float2(80, 0)));
				tests.Add(new ElementTest(wp.Children[5] as Element,  float2(20,40), float2(0, 40)));
				tests.Add(new ElementTest(wp.Children[6] as Element,  float2(20,40), float2(20, 40)));
				tests.Add(new ElementTest(wp.Children[7] as Element,  float2(20,40), float2(40, 40)));
				tests.Add(new ElementTest(wp.Children[8] as Element,  float2(20,40), float2(60, 40)));
				tests.Add(new ElementTest(wp.Children[9] as Element,  float2(20,40), float2(80, 40)));
				tests.Add(new ElementTest(wp.Children[10] as Element, float2(20,40), float2(0, 80)));

				RunElementTests(tests);
			}
		}

		[Test]
		public void FlowDirectionRightToLeft()
		{
			var wp = CreateWPWithElements(11, float2(20, 40));
			wp.FlowDirection = FlowDirection.RightToLeft;

			using (var root = TestRootPanel.CreateWithChild(wp, int2(100)))
			{
				List<ElementTest> tests = new List<ElementTest>();
				tests.Add(new ElementTest(wp.Children[0] as Element,  float2(20, 40), float2(100-20, 0)));
				tests.Add(new ElementTest(wp.Children[1] as Element,  float2(20, 40), float2(100-40, 0)));
				tests.Add(new ElementTest(wp.Children[2] as Element,  float2(20, 40), float2(100-60, 0)));
				tests.Add(new ElementTest(wp.Children[3] as Element,  float2(20, 40), float2(100-80, 0)));
				tests.Add(new ElementTest(wp.Children[4] as Element,  float2(20, 40), float2(0, 0)));
				tests.Add(new ElementTest(wp.Children[5] as Element,  float2(20, 40), float2(100-20, 40)));
				tests.Add(new ElementTest(wp.Children[6] as Element,  float2(20, 40), float2(100-40, 40)));
				tests.Add(new ElementTest(wp.Children[7] as Element,  float2(20, 40), float2(100-60, 40)));
				tests.Add(new ElementTest(wp.Children[8] as Element,  float2(20, 40), float2(100-80, 40)));
				tests.Add(new ElementTest(wp.Children[9] as Element,  float2(20, 40), float2(0, 40)));
				tests.Add(new ElementTest(wp.Children[10] as Element, float2(20, 40), float2(100-20, 80)));

				RunElementTests(tests);
			}
		}

		[Test]
		public void OrientationVertical()
		{
			var wp = CreateWPWithElements(10, float2(20,40));
			wp.Orientation = Orientation.Vertical;
			wp.FlowDirection = FlowDirection.RightToLeft;
			using (var root = TestRootPanel.CreateWithChild(wp, int2(100)))
			{
				List<ElementTest> tests = new List<ElementTest>();
				tests.Add(new ElementTest(wp.Children[0] as Element,  float2(20, 40), float2(100-20, 0)));
				tests.Add(new ElementTest(wp.Children[1] as Element,  float2(20, 40), float2(100-20, 40)));
				tests.Add(new ElementTest(wp.Children[2] as Element,  float2(20, 40), float2(100-40, 0)));
				tests.Add(new ElementTest(wp.Children[3] as Element,  float2(20, 40), float2(100-40, 40)));
				tests.Add(new ElementTest(wp.Children[4] as Element,  float2(20, 40), float2(100-60, 0)));
				tests.Add(new ElementTest(wp.Children[5] as Element,  float2(20, 40), float2(100-60, 40)));
				tests.Add(new ElementTest(wp.Children[6] as Element,  float2(20, 40), float2(100-80, 0)));
				tests.Add(new ElementTest(wp.Children[7] as Element,  float2(20, 40), float2(100-80, 40)));
				tests.Add(new ElementTest(wp.Children[8] as Element,  float2(20, 40), float2(0, 0)));
				tests.Add(new ElementTest(wp.Children[9] as Element,  float2(20, 40), float2(0, 40)));

				RunElementTests(tests);
			}
		}

		[Test]
		public void OrientationVerticalFlowDirectionRightToLeft()
		{
			var wp = CreateWPWithElements(10, float2(20,40));
			wp.Orientation = Orientation.Vertical;

			using (var root = TestRootPanel.CreateWithChild(wp, int2(100)))
			{
				List<ElementTest> tests = new List<ElementTest>();
				tests.Add(new ElementTest(wp.Children[0] as Element,  float2(20, 40), float2(0,0)));
				tests.Add(new ElementTest(wp.Children[1] as Element,  float2(20, 40), float2(0,40)));
				tests.Add(new ElementTest(wp.Children[2] as Element,  float2(20, 40), float2(20,0)));
				tests.Add(new ElementTest(wp.Children[3] as Element,  float2(20, 40), float2(20,40)));
				tests.Add(new ElementTest(wp.Children[4] as Element,  float2(20, 40), float2(40,0)));
				tests.Add(new ElementTest(wp.Children[5] as Element,  float2(20, 40), float2(40,40)));
				tests.Add(new ElementTest(wp.Children[6] as Element,  float2(20, 40), float2(60,0)));
				tests.Add(new ElementTest(wp.Children[7] as Element,  float2(20, 40), float2(60,40)));
				tests.Add(new ElementTest(wp.Children[8] as Element,  float2(20, 40), float2(80,0)));
				tests.Add(new ElementTest(wp.Children[9] as Element,  float2(20, 40), float2(80,40)));

				RunElementTests(tests);
			}
		}

		[Test]
		public void VaryingSizeTest()
		{
			var wp = new WrapPanel();

			wp.Children.Add(new DummyElement(float2(10,40)));
			wp.Children.Add(new DummyElement(float2(5, 16)));
			wp.Children.Add(new DummyElement(float2(72,64)));
			wp.Children.Add(new DummyElement(float2(11,23)));
			wp.Children.Add(new DummyElement(float2(17,5)));
			wp.Children.Add(new DummyElement(float2(22,11)));
			wp.Children.Add(new DummyElement(float2(2, 21)));
			wp.Children.Add(new DummyElement(float2(73,22)));
			wp.Children.Add(new DummyElement(float2(10,6)));
			wp.Children.Add(new DummyElement(float2(25,8)));

			using (var root = TestRootPanel.CreateWithChild(wp, int2(100)))
			{
				List<ElementTest> tests = new List<ElementTest>();
				tests.Add(new ElementTest(wp.Children[0] as Element,  float2(10,64), float2(0,0)));
				tests.Add(new ElementTest(wp.Children[1] as Element,  float2(5, 64), float2(10,0)));
				tests.Add(new ElementTest(wp.Children[2] as Element,  float2(72,64), float2(15,0)));
				tests.Add(new ElementTest(wp.Children[3] as Element,  float2(11,64), float2(87,0)));
				tests.Add(new ElementTest(wp.Children[4] as Element,  float2(17,21), float2(0,64)));
				tests.Add(new ElementTest(wp.Children[5] as Element,  float2(22,21), float2(17,64)));
				tests.Add(new ElementTest(wp.Children[6] as Element,  float2(2, 21), float2(39,64)));
				tests.Add(new ElementTest(wp.Children[7] as Element,  float2(73,22), float2(0,64+21)));
				tests.Add(new ElementTest(wp.Children[8] as Element,  float2(10,22), float2(73, 64+21)));
				tests.Add(new ElementTest(wp.Children[9] as Element,  float2(25,8), float2(0,107)));

				RunElementTests(tests);
			}
		}

		WrapPanel CreateWPWithElements(int n, float2 itemSize)
		{
			var wp = CreateWPWithElements(n);
			wp.ItemWidth = itemSize.X;
			wp.ItemHeight = itemSize.Y;
			return wp;
		}

		WrapPanel CreateWPWithElements(int n)
		{
			var wp = new WrapPanel();
			for (int i = 0; i < n; i++)
			{
				var e = new DummyElement();
				wp.Children.Add(e);
			}
			return wp;
		}

		void RunElementTests(List<ElementTest> tests)
		{
			foreach (var t in tests)
				LayoutTestHelper.TestElementLayout(t.Element, t.ExpectedPos, t.ExpectedSize);
		}

		[Test]
		public void Issue2680()
		{
			var p = new UX.Issue2680();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(float2(300,40), p.G.ActualSize);
			}
		}

		[Test]
		public void Max()
		{
			var p = new UX.WrapPanel.Max();
			using (var root = TestRootPanel.CreateWithChild(p,int2(200)))
			{
				Assert.AreEqual(float4(10,10,80,100), ActualPositionSize(p.F));
				Assert.AreEqual(float2(100,120), p.W.ActualSize);
				Assert.AreEqual(float2(100,120), p.B.ActualSize);
				Assert.AreEqual(float2(80,100), p.O.ActualSize);

				Assert.AreEqual(float4(10,10,80,100), ActualPositionSize(p.F2));
				Assert.AreEqual(float2(100,120), p.W2.ActualSize);
				Assert.AreEqual(float2(100,120), p.B2.ActualSize);
				Assert.AreEqual(float2(80,100), p.O2.ActualSize);
			}
		}

		[Test]
		public void VerticalRightToLeft()
		{
			var p = new UX.WrapPanel.VerticalRightToLeft();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000)))
			{
				var right = 1000 - p.W.Padding.Z;
				var top = p.W.Padding.Y;
				Assert.AreEqual( float4(right-50, top, 50, 50), ActualPositionSize(p.P1));
				Assert.AreEqual( float4(right-60, top+50, 60, 40), ActualPositionSize(p.P2));
				Assert.AreEqual( float4(right-70, top, 10, 40), ActualPositionSize(p.P3));
				Assert.AreEqual( float4(right-100, top+10, 20, 50), ActualPositionSize(p.P4));
			}
		}

		[Test]
		public void Center()
		{
			var p = new UX.WrapPanel.Center();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000)))
			{
				Assert.AreEqual( float4(2,2,30*4,90), ActualPositionSize(p.W) );
			}
		}

		[Test]
		public void ChildSize()
		{
			var p = new UX.WrapPanel.ChildSize();
			using (var root = TestRootPanel.CreateWithChild(p,int2(700,100))) //height shouldn't matter
			{
				Assert.AreEqual( float4(5,5,190,20), ActualPositionSize(p.P1));
				Assert.AreEqual( float4(205,5,190,20), ActualPositionSize(p.P2));
				Assert.AreEqual( float4(405,5,190,20), ActualPositionSize(p.P3));
				Assert.AreEqual( float4(5,35,190,20), ActualPositionSize(p.P4));
			}
		}

		[Test]
		public void ItemSize()
		{
			var p = new UX.WrapPanel.ItemSize();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000)))
			{
				Assert.AreEqual( float4(0,0,20,50), ActualPositionSize(p.A1));
				Assert.AreEqual( float4(20,0,2,50), ActualPositionSize(p.A2));
				Assert.AreEqual( float4(0,0,10,100), ActualPositionSize(p.A3));
				Assert.AreEqual( float4(10,0,10,10), ActualPositionSize(p.A4));
			}
		}

		[Test]
		public void RowAlignment()
		{
			var p = new UX.WrapPanel.RowAlignment();
			using (var root = TestRootPanel.CreateWithChild(p,int2(200,1000)))
			{
				Assert.AreEqual( float4(0,4,100,2), ActualPositionSize(p.P1));
				Assert.AreEqual( float4(100,0,100,10), ActualPositionSize(p.P2));
				Assert.AreEqual( float4(0,10,100,30), ActualPositionSize(p.P3));
				Assert.AreEqual( float4(100,15,100,20), ActualPositionSize(p.P4));

				Assert.AreEqual( float4(0,4,100,2), ActualPositionSize(p.RC1));
				Assert.AreEqual( float4(100,0,100,10), ActualPositionSize(p.RC2));
				Assert.AreEqual( float4(50,10,100,30), ActualPositionSize(p.RC3));

				Assert.AreEqual( float4(-150,0,500,2), ActualPositionSize(p.RO1));

				Assert.AreEqual( float4(0,0,2,100), ActualPositionSize(p.VT1));
				Assert.AreEqual( float4(0,100,10,100), ActualPositionSize(p.VT2));
				Assert.AreEqual( float4(10,0,30,100), ActualPositionSize(p.VT3));
				Assert.AreEqual( float4(10,100,20,100), ActualPositionSize(p.VT4));

				Assert.AreEqual( float4(4,0,2,100), ActualPositionSize(p.VC1));
				Assert.AreEqual( float4(0,100,10,100), ActualPositionSize(p.VC2));
				Assert.AreEqual( float4(10,0,30,100), ActualPositionSize(p.VC3));
				Assert.AreEqual( float4(15,100,20,100), ActualPositionSize(p.VC4));

				Assert.AreEqual( float4(8,0,2,100), ActualPositionSize(p.VB1));
				Assert.AreEqual( float4(0,100,10,100), ActualPositionSize(p.VB2));
				Assert.AreEqual( float4(10,0,30,100), ActualPositionSize(p.VB3));
				Assert.AreEqual( float4(20,100,20,100), ActualPositionSize(p.VB4));

				// Old RowAlignment tests
				Assert.AreEqual( float4(0,4,100,2), ActualPositionSize(p.RP1));
				Assert.AreEqual( float4(100,0,100,10), ActualPositionSize(p.RP2));
				Assert.AreEqual( float4(0,10,100,30), ActualPositionSize(p.RP3));
				Assert.AreEqual( float4(100,15,100,20), ActualPositionSize(p.RP4));

				Assert.AreEqual( float4(8,0,2,100), ActualPositionSize(p.RR1));
				Assert.AreEqual( float4(0,100,10,100), ActualPositionSize(p.RR2));
				Assert.AreEqual( float4(10,0,30,100), ActualPositionSize(p.RR3));
				Assert.AreEqual( float4(20,100,20,100), ActualPositionSize(p.RR4));
			}
		}

		[Test]
		public void Invalidate()
		{
			var p = new UX.WrapPanel.Invalidate();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000)))
			{
				Assert.AreEqual( float2(50,50), p.p1.ActualSize );
				Assert.AreEqual( float2(50,0), p.p2.ActualPosition );

				p.wp.ItemHeight = 40;
				root.StepFrame();
				Assert.AreEqual( float2(50,40), p.p1.ActualSize );
				Assert.AreEqual( float2(50,0), p.p2.ActualPosition );

				p.wp.Orientation = Orientation.Vertical;
				root.StepFrame();
				Assert.AreEqual( float2(50,40), p.p1.ActualSize );
				Assert.AreEqual( float2(0,40), p.p2.ActualPosition );
			}
		}

	}
}
