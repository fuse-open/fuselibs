using Uno;
using Uno.UX;
using Uno.Collections;
using Uno.Testing;

using Fuse;
using Fuse.Controls;
using Fuse.Elements;

namespace FuseTest
{

	public static class ElementLayoutTester
	{

		public static void All(Element elm)
		{
			DesiredSizeWithMinWidth(elm);
			ResetElementProperties(elm);

			DesiredSizeWithMinHeight(elm);
			ResetElementProperties(elm);

			DesiredSizeWithMinBounds(elm);
			ResetElementProperties(elm);

			DesiredSizeWithMaxWidth(elm);
			ResetElementProperties(elm);

			DesiredSizeWithMaxHeight(elm);
			ResetElementProperties(elm);

			DesiredSizeWithMaxBounds(elm);
			ResetElementProperties(elm);

			TestHorizontalAlignment(elm, Alignment.Left);
			ResetElementProperties(elm);

			TestHorizontalAlignment(elm, Alignment.Right);
			ResetElementProperties(elm);

			TestHorizontalAlignment(elm, Alignment.Default);
			ResetElementProperties(elm);

			TestHorizontalAlignment(elm, Alignment.HorizontalCenter);
			ResetElementProperties(elm);

			TestVerticalAlignment(elm, Alignment.Top);
			ResetElementProperties(elm);

			TestVerticalAlignment(elm, Alignment.Bottom);
			ResetElementProperties(elm);

			TestVerticalAlignment(elm, Alignment.Default);
			ResetElementProperties(elm);
			
			TestVerticalAlignment(elm, Alignment.HorizontalCenter);
			ResetElementProperties(elm);

			var margin = float4(1f, 2f, 3f, 4f);
			var padding = float4(5f, 6f, 7f, 8f);

			for (int i = 0; i < 5; i++)
			{
				TestPlacementWithMarginAndPadding(elm, Alignment.BottomRight, margin, padding);
				margin += margin;
				padding += padding;
			}

		}

		static void ResetElementProperties(Element elm)
		{
			elm.Width = Size.Auto;
			elm.Height = Size.Auto;
			elm.MaxWidth = Size.Auto;
			elm.MaxHeight = Size.Auto;
			elm.MinWidth = Size.Auto;
			elm.MinHeight = Size.Auto;
			elm.Alignment = Alignment.Default;
			elm.SnapToPixels = false;
			elm.Margin = float4(0);
			elm.Padding = float4(0);
		}

		public static void DesiredSizeWithMinWidth(Element elm)
		{

			elm.Alignment = Alignment.Center;
			
			elm.MinWidth = 100;
			elm.SnapToPixels = false;
			elm.ArrangeMarginBox(float2(0),LayoutParams.Create(float2(1000f)));
			
			Assert.AreEqual(100, elm.ActualSize.X);
		}

		public static void DesiredSizeWithMinHeight(Element elm)
		{

			elm.Alignment = Alignment.Center;

			elm.MinHeight = 100;
			elm.SnapToPixels = false;
			elm.ArrangeMarginBox(float2(0),LayoutParams.Create(float2(1000f)));

			Assert.AreEqual(100, elm.ActualSize.Y);
		}

		public static void DesiredSizeWithMinBounds(Element elm)
		{

			elm.Alignment = Alignment.Center;

			elm.MinWidth = 200;
			elm.MinHeight = 200;
			elm.SnapToPixels = false;

			elm.ArrangeMarginBox(float2(0),LayoutParams.Create(float2(1000f)));

			Assert.AreEqual(200, elm.ActualSize.X);
			Assert.AreEqual(200, elm.ActualSize.Y);
		}

		public static void DesiredSizeWithMaxWidth(Element elm)
		{
			elm.MaxWidth = 300;
			elm.Width = 400;
			elm.SnapToPixels = false;

			elm.ArrangeMarginBox(float2(0),LayoutParams.Create(float2(1000f)));

			Assert.AreEqual(300, elm.ActualSize.X);

		}

		public static void DesiredSizeWithMaxHeight(Element elm)
		{
			elm.MaxHeight = 400;
			elm.Height = 500;
			elm.SnapToPixels = false;

			elm.ArrangeMarginBox(float2(0),LayoutParams.Create(float2(1000f)));

			Assert.AreEqual(400, elm.ActualSize.Y);
		}

		public static void DesiredSizeWithMaxBounds(Element elm)
		{
			elm.MaxWidth = 200;
			elm.MaxHeight = 300;
			elm.SnapToPixels = false;

			elm.Height = 2000;
			elm.Width = 2000;

			elm.ArrangeMarginBox(float2(0),LayoutParams.Create(float2(1000f)));

			Assert.AreEqual(200, elm.ActualSize.X);
			Assert.AreEqual(300, elm.ActualSize.Y);
		}

		public static void TestHorizontalAlignment(Element elm, Alignment alignment)
		{
			elm.Width = 200;
			elm.Height = 200;
			elm.SnapToPixels = false;

			elm.Alignment = alignment;

			elm.ArrangeMarginBox(float2(0f), LayoutParams.Create(float2(1000f)));

			switch (alignment)
			{
				case Alignment.Left:
				{
					Assert.AreEqual(0, elm.ActualPosition.X);
					Assert.AreEqual(400, elm.ActualPosition.Y);
					return;
				}
				case Alignment.Right:
				{
					Assert.AreEqual(800, elm.ActualPosition.X);
					Assert.AreEqual(400, elm.ActualPosition.Y);
					return;
				}
				case Alignment.Default:
				{
					Assert.AreEqual(400, elm.ActualPosition.X);
					Assert.AreEqual(400, elm.ActualPosition.Y);
					return;
				}
				case Alignment.HorizontalCenter:
				{
					Assert.AreEqual(400, elm.ActualPosition.X);
					Assert.AreEqual(400, elm.ActualPosition.Y);
					return;
				}
			}
			Assert.Fail("Something went wrong");
		}

		public static void TestVerticalAlignment(Element elm, Alignment alignment)
		{
			elm.Width = 200;
			elm.Height = 200;
			elm.SnapToPixels = false;

			elm.Alignment = alignment;

			elm.ArrangeMarginBox(float2(0f), LayoutParams.Create(float2(1000f)));

			switch (alignment)
			{
				case Alignment.Top:
				{
					Assert.AreEqual(400, elm.ActualPosition.X);
					Assert.AreEqual(0, elm.ActualPosition.Y);
					return;
				}
				case Alignment.Bottom:
				{
					Assert.AreEqual(400, elm.ActualPosition.X);
					Assert.AreEqual(800, elm.ActualPosition.Y);
					return;
				}
				case Alignment.Default:
				{
					Assert.AreEqual(400, elm.ActualPosition.X);
					Assert.AreEqual(400, elm.ActualPosition.Y);
					return;
				}
				case Alignment.HorizontalCenter:
				{
					Assert.AreEqual(400, elm.ActualPosition.X);
					Assert.AreEqual(400, elm.ActualPosition.Y);
					return;
				}
			}
			Assert.Fail("Something went wrong");
		}

		public static void TestCombinedAlignment(Element elm, Alignment combined)
		{
			elm.Width = 200;
			elm.Height = 200;
			elm.SnapToPixels = false;

			elm.Alignment = combined;

			elm.ArrangeMarginBox(float2(0f), LayoutParams.Create(float2(1000f)));

			switch (AlignmentHelpers.GetHorizontalAlign(combined))
			{
				case Alignment.Left: Assert.AreEqual(0, elm.ActualPosition.X); break;
				case Alignment.Right: Assert.AreEqual(800, elm.ActualPosition.X); break;
				case Alignment.Default: Assert.AreEqual(400, elm.ActualPosition.X); break;
				case Alignment.HorizontalCenter: Assert.AreEqual(400, elm.ActualPosition.X); break;
			}

			switch (AlignmentHelpers.GetVerticalAlign(combined))
			{
				case Alignment.Top: Assert.AreEqual(0, elm.ActualPosition.Y); break;
				case Alignment.Bottom: Assert.AreEqual(800, elm.ActualPosition.Y); break;
				case Alignment.Default:	Assert.AreEqual(400, elm.ActualPosition.Y);	break;
				case Alignment.HorizontalCenter: Assert.AreEqual(400, elm.ActualPosition.Y); break;
			}
		}

		public static void TestPlacementWithMarginAndPadding(Element elm, Alignment align, float4 margin = float4(0f), float4 padding = float4(0f))
		{

			var panel = new Panel()
			{
				Padding = padding,
				Width = 1000f,
				Height = 1000f,
			};

			panel.SnapToPixels = false;
			panel.ArrangeMarginBox(float2(0f), LayoutParams.Create(float2(1000f)));

			panel.Children.Add(elm);

			elm.Width = 200;
			elm.Height = 200;
			elm.Margin = margin;
			elm.SnapToPixels = false;
			
			elm.Alignment = align;

			elm.ArrangeMarginBox(float2(0f), LayoutParams.Create(float2(1000f)));

			panel.ArrangeMarginBox(float2(0f), LayoutParams.Create(float2(1000f)));

			switch (AlignmentHelpers.GetHorizontalAlign(align))
			{
				case Alignment.Left:
					Assert.AreEqual(margin.X + padding.X, elm.ActualPosition.X);
					break;

				case Alignment.Right:
					Assert.AreEqual(800.0f - margin.Z - padding.Z, elm.ActualPosition.X);
					break;

				case Alignment.Default:
					Assert.AreEqual(400.0f + ((margin.X + padding.X) * 0.5f - (margin.Z + padding.Z) * 0.5f), elm.ActualPosition.X);
					break;

				case Alignment.HorizontalCenter:
					Assert.AreEqual(400.0f + ((margin.X + padding.X) - (margin.Z + padding.Z)) * 0.5f, elm.ActualPosition.X);
					break;

			}

			switch (AlignmentHelpers.GetVerticalAlign(align))
			{
				case Alignment.Top:
					Assert.AreEqual(margin.Y + padding.Y, elm.ActualPosition.Y);
					break;

				case Alignment.Bottom:
					Assert.AreEqual(800 - margin.W - padding.W, elm.ActualPosition.Y);
					break;

				case Alignment.Default:
					Assert.AreEqual(400 + ((margin.Y + padding.Y) * 0.5f - (margin.W + padding.W) * 0.5f) , elm.ActualPosition.Y);
					break;

				case Alignment.HorizontalCenter:
					Assert.AreEqual(400 + ((margin.Y + padding.Y) - (margin.W + padding.W)) * 0.5f, elm.ActualPosition.Y);
					break;
			}

			panel.Children.Remove(elm);
		}


		public static void TestAllAlignments(Element elm)
		{
			for (int x = 0; x < 4; x++)
			{
				for (int y = 0; y < 4; y++)
				{
					var h = (Alignment)x;
					var v = (Alignment)(y<<2);
					TestCombinedAlignment(elm, h|v);
				}
			}
		}

	}
}