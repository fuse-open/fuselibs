using Uno;
using Uno.UX;
using Uno.Collections;
using Uno.Testing;

using Fuse;
using Fuse.Controls;
using Fuse.Elements;

namespace FuseTest
{
	public static class ElementPropertyTester
	{
		public static void All(Element elm)
		{
			GetSetWidth(elm);
			GetSetHeight(elm);
			GetSetMinWidth(elm);
			GetSetMinHeight(elm);
			GetSetMaxWidth(elm);
			GetSetMaxHeight(elm);
			GetSetAlignment(elm);
			GetSetVisibility(elm);
			GetSetMargin(elm);
			GetSetPadding(elm);
			GetSetSnapToPixels(elm);
			
			///
			/// GitHub #1191
			///
			if (!(elm is Fuse.Controls.ScrollView))
				GetSetClipToBounds(elm);



			GetSetCachingMode(elm);
			
			GetSetIsEnabled(elm);

			//NodeTester.TestAll(elm);
		}

		public static void GetSetWidth(Element elm)
		{
			Assert.IsTrue(elm.Width.IsAuto);

			elm.Width = Size.Points(100);
			Assert.AreEqualSize(Size.Points(100), elm.Width);

			elm.Width = Size.Auto;
			Assert.IsTrue(elm.Width.IsAuto);
		}

		public static void GetSetHeight(Element elm)
		{
			Assert.IsTrue(elm.Height.IsAuto);

			elm.Height = Size.Points(100);
			Assert.AreEqualSize(Size.Points(100), elm.Height);

			elm.Height = Size.Auto;
			Assert.IsTrue(elm.Height.IsAuto);
		}

		public static void GetSetMinWidth(Element elm)
		{
			Assert.IsFalse(elm.HasBit(FastProperty1.MinWidth));

			elm.MinWidth = Size.Points(200);
			Assert.AreEqualSize(Size.Points(200), elm.MinWidth);

			elm.MinWidth = Size.Auto;
			Assert.IsFalse(elm.HasBit(FastProperty1.MinWidth));
		}

		public static void GetSetMinHeight(Element elm)
		{
			Assert.IsFalse(elm.HasBit(FastProperty1.MinHeight));

			elm.MinHeight = Size.Points(200);
			Assert.AreEqualSize(Size.Points(200), elm.MinHeight);

			elm.MinHeight = Size.Auto;
			Assert.IsFalse(elm.HasBit(FastProperty1.MinHeight));
		}

		public static void GetSetMaxWidth(Element elm)
		{
			Assert.IsFalse(elm.HasBit(FastProperty1.MaxWidth));

			elm.MaxWidth = Size.Points(300);
			Assert.AreEqualSize(Size.Points(300), elm.MaxWidth);

			elm.MaxWidth = Size.Auto;
			Assert.IsFalse(elm.HasBit(FastProperty1.MaxWidth));
		}

		public static void GetSetMaxHeight(Element elm)
		{
			Assert.IsFalse(elm.HasBit(FastProperty1.MaxHeight));

			elm.MaxHeight = Size.Points(400);
			Assert.AreEqualSize(Size.Points(400), elm.MaxHeight);

			elm.MaxHeight = Size.Auto;

			Assert.IsFalse(elm.HasBit(FastProperty1.MaxHeight));
		}

		public static void GetSetAlignment(Element elm)
		{
			Assert.AreEqual(elm.Alignment, Alignment.Default);

			elm.Alignment = Alignment.HorizontalCenter;
			Assert.AreEqual(Alignment.HorizontalCenter, elm.Alignment);

			elm.Alignment = Alignment.Left;
			Assert.AreEqual(Alignment.Left, elm.Alignment);

			elm.Alignment = Alignment.Default;

			Assert.AreEqual(Alignment.Default, elm.Alignment);
		}

		public static void GetSetVisibility(Element elm)
		{
			Assert.AreEqual(elm.Visibility, Visibility.Visible);

			elm.Visibility = Visibility.Collapsed;
			Assert.AreEqual(Visibility.Collapsed, elm.Visibility);

			elm.Visibility = Visibility.Hidden;
			Assert.AreEqual(Visibility.Hidden, elm.Visibility);

			elm.Visibility = Visibility.Visible;
			Assert.AreEqual(Visibility.Visible, elm.Visibility);
		}

		public static void GetSetMargin(Element elm)
		{
			Assert.IsFalse(elm.HasBit(FastProperty1.Margin));

			elm.Margin = float4(10, 20, 30, 40);
			Assert.AreEqual(float4(10, 20, 30, 40), elm.Margin);

			elm.Margin = float4(80, 70, 60, 50);
			Assert.AreEqual(float4(80, 70, 60, 50), elm.Margin);

			elm.Margin = float4(0);
			Assert.IsFalse(elm.HasBit(FastProperty1.Margin));
			Assert.AreEqual(float4(0), elm.Margin);
		}

		public static void GetSetPadding(Element elm)
		{
			Assert.IsFalse(elm.HasBit(FastProperty1.Padding));

			elm.Padding = float4(1, 2, 3, 4);
			Assert.AreEqual(float4(1, 2, 3, 4), elm.Padding);

			elm.Padding = float4(8, 7, 6, 5);
			Assert.AreEqual(float4(8, 7, 6, 5), elm.Padding);

			elm.Padding = float4(0);
			Assert.IsFalse(elm.HasBit(FastProperty1.Padding));
			Assert.AreEqual(float4(0), elm.Padding);
		}

		public static void GetSetSnapToPixels(Element elm)
		{
			Assert.IsTrue(elm.HasBit(FastProperty1.SnapToPixels));

			elm.SnapToPixels = true;
			Assert.IsTrue(elm.SnapToPixels);

			elm.SnapToPixels = false;
			Assert.IsFalse(elm.SnapToPixels);

			elm.SnapToPixels = true;
			Assert.IsTrue(elm.HasBit(FastProperty1.SnapToPixels));
			Assert.IsTrue(elm.SnapToPixels);
		}

		public static void GetSetClipToBounds(Element elm)
		{
			Assert.IsFalse(elm.HasBit(FastProperty1.ClipToBounds));

			elm.ClipToBounds = true;
			Assert.IsTrue(elm.ClipToBounds);

			elm.ClipToBounds = false;
			Assert.IsFalse(elm.ClipToBounds);
			Assert.IsFalse(elm.HasBit(FastProperty1.ClipToBounds));
		}

		public static void GetSetCachingMode(Element elm)
		{
			elm.CachingMode = CachingMode.Always;
			Assert.AreEqual(CachingMode.Always, elm.CachingMode);

			elm.CachingMode = CachingMode.Never;
			Assert.AreEqual(CachingMode.Never, elm.CachingMode);

			elm.CachingMode = CachingMode.Optimized;
			Assert.AreEqual(CachingMode.Optimized, elm.CachingMode);
		}

		public static void GetSetIsEnabled(Element elm)
		{
			elm.IsEnabled = true;
			Assert.IsTrue(elm.IsContextEnabled);

			elm.IsEnabled = false;
			Assert.IsFalse(elm.IsContextEnabled);
		}



	}
}
