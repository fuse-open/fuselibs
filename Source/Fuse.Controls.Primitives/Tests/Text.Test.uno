using Uno.Testing;
using FuseTest;

namespace Fuse.Controls.Primitives.Test
{
	public class TextTest : TestBase
	{
		[Test]
		public void LineSpacingAffectsHeight()
		{
			var e = new UX.LineSpacingText();
			var sp = new StackPanel();
			sp.Children.Add(e);
			using (var root = TestRootPanel.CreateWithChild(sp))
			{
				Assert.IsTrue(e.ActualSize.Y > 0);

				var previousHeight = e.ActualSize.Y;
				e.LineSpacing = 10;
				root.UpdateLayout();
				Assert.IsTrue(e.ActualSize.Y > previousHeight);

				previousHeight = e.ActualSize.Y;
				e.LineSpacing = 20;
				root.UpdateLayout();
				Assert.IsTrue(e.ActualSize.Y > previousHeight);
			}
		}

		[Test]
		public void TextWrappingAffectsSize()
		{
			var e = new UX.TextWrappingText();
			var sp = new StackPanel();
			sp.Children.Add(e);
			using (var root = TestRootPanel.CreateWithChild(sp, int2(100, 600)))
			{
				var noWrapSize = e.ActualSize;
				Assert.IsTrue(noWrapSize.X > 0 && noWrapSize.Y > 0);

				e.TextWrapping = TextWrapping.Wrap;
				root.UpdateLayout();
				var wrapSize = e.ActualSize;

				Assert.IsTrue(wrapSize.Y > noWrapSize.Y);
			}
		}

		[Test]
		public extern(USE_HARFBUZZ) void TextTruncationAffectsRenderBounds()
		{
			var e = new UX.TextWrappingText();
			var sp = new StackPanel();
			sp.Children.Add(e);
			using (var root = TestRootPanel.CreateWithChild(sp, int2(100, 600)))
			{
				root.TestDraw();
				var noneTruncatedSize = e.RenderBoundsWithoutEffects.FlatRect.Size;
				Assert.IsTrue(noneTruncatedSize.X > 0 && noneTruncatedSize.Y > 0);

				e.TextTruncation = TextTruncation.Standard;
				root.UpdateLayout();
				root.TestDraw();
				var truncatedSize = e.RenderBoundsWithoutEffects.FlatRect.Size;

				Assert.IsTrue(truncatedSize.X < noneTruncatedSize.X);
			}
		}

		[Test]
		[Ignore("https://github.com/fuse-open/fuselibs/issues/671", "Android || iOS")]
		public void FontSizeAffectsHeight()
		{
			var e = new UX.TextWrappingText();
			var sp = new StackPanel();
			sp.Children.Add(e);
			using (var root = TestRootPanel.CreateWithChild(sp))
			{
				var smallSize = e.ActualSize;
				Assert.IsTrue(smallSize.X > 0 && smallSize.Y > 0);

				e.FontSize = 100;
				root.UpdateLayout();
				var bigSize = e.ActualSize;

				Assert.IsTrue(bigSize.Y > smallSize.Y);
			}
		}
	}
}
