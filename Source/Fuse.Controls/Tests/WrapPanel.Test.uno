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
using FuseTest;
using Fuse.Controls.Test.Helpers;
using Fuse.Layouts;

namespace Fuse.Controls.Test
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
			var root = new TestRootPanel();

			var wp = CreateWPWithElements(11, float2(20,40));
			root.Children.Add(wp);
			root.Layout(int2(100));

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

		[Test]
		public void FlowDirectionRightToLeft()
		{
			var root = new TestRootPanel();
			var wp = CreateWPWithElements(11, float2(20, 40));
			root.Children.Add(wp);

			wp.FlowDirection = FlowDirection.RightToLeft;

			root.Layout(int2(100));

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

		[Test]
		public void OrientationVertical()
		{
			var root = new TestRootPanel();
			var wp = CreateWPWithElements(10, float2(20,40));
			wp.Orientation = Orientation.Vertical;
			wp.FlowDirection = FlowDirection.RightToLeft;
			root.Children.Add(wp);
			root.Layout(int2(100));

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

		[Test]
		public void OrientationVerticalFlowDirectionRightToLeft()
		{
			var root = new TestRootPanel();
			var wp = CreateWPWithElements(10, float2(20,40));

			wp.Orientation = Orientation.Vertical;
			root.Children.Add(wp);
			root.Layout(int2(100));

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

		[Test]
		public void VaryingSizeTest()
		{
			var root = new TestRootPanel();
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

			root.Children.Add(wp);
			root.Layout(int2(100));


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
	}
}
