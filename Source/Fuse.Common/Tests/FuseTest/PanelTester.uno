using Uno;
using Uno.UX;
using Uno.Collections;
using Uno.Testing;

using Fuse;
using Fuse.Elements;
using Fuse.Controls;

namespace FuseTest
{
	public class PanelTester
	{
		public static void AllSimpleTests(Panel panelToTest)
		{
			AddChildrensTest(panelToTest);
			AddAndRemoveChildrensTest(panelToTest);
			HasChildrenTest(panelToTest);
		}

		public static void AllLayoutTests(Panel panelToTest)
		{
			if (panelToTest.Parent != null)
			{
				throw new Exception("Incoming panel already has a parent: " + panelToTest.Parent);
			}
			LayoutAlignment(panelToTest);
			SnappingToPixels(panelToTest);
			MaxAndMinWidthTest(panelToTest);
			MaxAndMinHeightTest(panelToTest);
		}

		public static void AddChildrensTest(Panel panelToTest)
		{
			var p = new Panel();
			Assert.AreEqual(0, p.Children.Count);

			p.Children.Add(new Panel());
			p.Children.Add(new Panel());
			Assert.AreEqual(2, p.Children.Count);

			p.Children.Clear();
		}

		public static void AddAndRemoveChildrensTest(Panel panelToTest)
		{
			var p = new Panel();
			var childPanelToRemove = new Panel();
			p.Children.Add(new Panel());
			p.Children.Add(childPanelToRemove);
			p.Children.Remove(childPanelToRemove);

			Assert.AreEqual(1, p.Children.Count);

			p.Children.Clear();
		}

		public static void HasChildrenTest(Panel panelToTest)
		{
			var p = new Panel();
			Assert.AreEqual(false, p.HasChildren);

			p.Children.Add(new Panel());
			Assert.AreEqual(true, p.HasChildren);

			p.Children.Clear();
		}

		public static void LayoutAlignment(Panel panelToTest)
		{
			using (var root = new TestRootPanel(true))
			{
				var parent = new Panel();
				root.Children.Add(parent);

				FillPanelProperties(panelToTest, float4( 10, 5, 21, 13 ), 200, 50, Alignment.TopRight);
				parent.Children.Add(panelToTest);

				panelToTest.Alignment = Alignment.TopRight;
				LayoutTestHelper.TestElementLayout(root, panelToTest, int2(1000,500), float2(200,50), float2(1000-200-21,5));

				panelToTest.Alignment = Alignment.BottomLeft;
				LayoutTestHelper.TestElementLayout(root, panelToTest, int2(100,500), float2(200,50), float2(10,500-50-13));

				parent.Children.Clear();

				if (panelToTest.Parent == parent)
				{
					throw new Exception("parent.Children.Clear() is broken");
				}
				else if (panelToTest.Parent != null)
				{
					throw new Exception("Something's wrong");
				}
			}
		}

		public static void SnappingToPixels(Panel panelToTest)
		{
			var parent = new Panel();
			using (var root = new TestRootPanel(true))
			{
				root.Children.Add(parent);
				FillPanelProperties(panelToTest, float4( 10.2f, 5.3f, 21.4f, 13.7f ), 100, 71, Alignment.TopRight);
				parent.Children.Add( panelToTest );

				panelToTest.SnapToPixels = false;
				LayoutTestHelper.TestElementLayout(root, panelToTest, int2(420,80), float2(100, 71),
					float2(420 - 100 - 21.4f, 5.3f));

				root.Children.Remove(parent);
			}

			panelToTest.SnapToPixels = true;


			var screenDensity = 2f;
			using (var root = new TestRootPanel(false, screenDensity))
			{
				root.Children.Add(parent);

				LayoutTestHelper.TestElementLayout(root, panelToTest, int2(800,600),
					root.SnapToPixelsSize(float2(100, 71)), float2(800 - 100 - root.SnapToPixelsPos(21.4f),
					root.SnapToPixelsPos(5.3f)));

				root.Children.Remove(parent);
			}

			screenDensity = 0.75f;

			using (var root = new TestRootPanel(false, screenDensity))
			{
				root.Children.Add(parent);

				LayoutTestHelper.TestElementLayout(root, panelToTest, int2(600,600), 
					root.SnapToPixelsSize(float2(100, 71)) , float2(600 - 100 - root.SnapToPixelsPos(21.4f),
					root.SnapToPixelsPos(5.3f)), 0.0001f);

				root.Children.Remove(parent);
			}

			screenDensity = 1.4f;
			using (var root = new TestRootPanel(false, screenDensity))
			{
				root.Children.Add(parent);

				LayoutTestHelper.TestElementLayout(root, panelToTest, int2(900,600), 
					root.SnapToPixelsSize(float2(100, 71)) , float2(900 - 100 - root.SnapToPixelsPos(21.4f),
					root.SnapToPixelsPos(5.3f)), 0.0001f);

				panelToTest.SnapToPixels = false;
				parent.Children.Clear();

				root.Children.Remove(parent);
			}
		}

		public static void MaxAndMinWidthTest(Panel panelToTest)
		{
			var parent = new Panel();
			parent.Children.Add(panelToTest);

			using (var root = TestRootPanel.CreateWithChild(parent))
			{
				panelToTest.Width = Size.Auto;
				panelToTest.Alignment = Alignment.Default;
				panelToTest.Margin = float4(7, 15, 9, 3);
				panelToTest.MaxWidth = 347;
				panelToTest.Height = 72;

				LayoutTestHelper.TestElementLayout(root, panelToTest, int2(281, 515), float2(281-7-9, 72), float2(7, (515-72-3+15)/2f));
				LayoutTestHelper.TestElementLayout(root, panelToTest, int2(703, 95), float2(347, 72), float2((703-347-9+7)/2f, (95-72-3+15)/2f));

				panelToTest.MaxWidth = Size.Auto;
				panelToTest.Margin = float4(11, 12, 13, 14);
				panelToTest.MinWidth = 542;
				panelToTest.Height = 417;

				LayoutTestHelper.TestElementLayout(root, panelToTest, int2(341, 608), float2(542, 417), 
					float2(-101.5f, (608-417-14+12)/2f));
				LayoutTestHelper.TestElementLayout(root, panelToTest, int2(847, 609), float2(847-11-13, 417), float2(11, (609-417-14+12)/2f));

				panelToTest.Alignment = Alignment.Default;
				panelToTest.MinWidth = Size.Auto;
				parent.Children.Clear();
			}
		}

		public static void MaxAndMinHeightTest(Panel panelToTest)
		{
			var parent = new Panel();
			using (var root = TestRootPanel.CreateWithChild(parent))
			{
				parent.Children.Add(panelToTest);
				panelToTest.Height = Size.Auto;
				panelToTest.Margin = float4(8, 3, 16, 7);
				panelToTest.MaxHeight = 401;
				panelToTest.Width = 265;

				LayoutTestHelper.TestElementLayout(root, panelToTest, int2(602, 230), float2(265, 230-3-7), float2((602-265-16+8)/2f, 3));
				LayoutTestHelper.TestElementLayout(root, panelToTest, int2(482, 679), float2(265, 401), float2((482-265-16+8)/2f, (679-401-7+3)/2f));

				panelToTest.MaxHeight = Size.Auto;
				panelToTest.Height = Size.Auto;
				panelToTest.Margin = float4(8, 3, 16, 7);
				panelToTest.MinHeight = 401;
				panelToTest.Width = 265;

				LayoutTestHelper.TestElementLayout(root, panelToTest, int2(678, 299), float2(265, 401), float2((678-265-16+8)/2f, -53));
				LayoutTestHelper.TestElementLayout(root, panelToTest, int2(692, 703), float2(265, 703-7-3), float2((692-265-16+8)/2f, 3));

				panelToTest.MinHeight = Size.Auto;
				parent.Children.Clear();
			}
		}

		public static void FillPanelProperties(Panel panelToTest, float4 margin, float width, float height, Alignment align)
		{
			panelToTest.Margin = margin;
			panelToTest.Alignment = align;
			panelToTest.Width = width;
			panelToTest.Height = height;
		}
	}
}
