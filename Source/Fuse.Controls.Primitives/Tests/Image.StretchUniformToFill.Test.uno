using Uno;
using Uno.Testing;
using Uno.Testing.Assert;
using FuseTest;

namespace Fuse.Test
{
	public partial class ImageTest : TestBase
	{
		[Test]
		public void StretchUniformToFillTest()
		{
			var panel = new StackPanelScene5();
			using (var root = TestRootPanel.CreateWithChild(panel))
			{
				TestImageLayout(root, int2(1586, 896), panel.Image1, float2(1586, 896),
					float2(0, (896 - 1586)/2f),
					float2(1586, 896), float2(0));
				TestImageLayout(root, int2(1586, 896), panel.Image2, float2(1586, 896),
					float2(0, (896 - 1586)/2f),
					float2(1586, 896), float2(0));

				TestImageLayout(root, int2(527, 896), panel.Image1, float2(527, 896),
					float2((527 - 896)/2f, 0),
					float2(527, 896), float2(0));
				TestImageLayout(root, int2(527, 896), panel.Image2, float2(527, 896),
					float2((527 - 896)/2f, 0),
					float2(527, 896), float2(0));
			}
		}

		[Test]
		public void StretchUniformToFillSmallTest()
		{
			var panel = new StackPanelScene5();
			using (var root = TestRootPanel.CreateWithChild(panel))
			{
				TestImageLayout(root, int2(563, 39), panel.Image1, float2(563, 39),
					float2(0, (39 - 563)/2f),
					float2(563, 39), float2(0));
				TestImageLayout(root, int2(563, 39), panel.Image2, float2(563, 39),
					float2(0, (39 - 563)/2f),
					float2(563, 39), float2(0));

				TestImageLayout(root, int2(114, 833), panel.Image1, float2(114, 833),
					float2((114 - 833)/2f, 0),
					float2(114, 833), float2(0));
				TestImageLayout(root, int2(114, 833), panel.Image2, float2(114, 833),
					float2((114 - 833)/2f, 0),
					float2(114, 833), float2(0));

				TestImageLayout(root, int2(55, 29), panel.Image1, float2(55, 29),
					float2(0, (29 - 55)/2f),
					float2(55, 29), float2(0));
				TestImageLayout(root, int2(55, 29), panel.Image2, float2(55, 29),
					float2(0, (29 - 55)/2f),
					float2(55, 29), float2(0));

				TestImageLayout(root, int2(23, 43), panel.Image1, float2(23, 43),
					float2((23 - 43)/2f, 0),
					float2(23, 43), float2(0));
				TestImageLayout(root, int2(23, 43), panel.Image2, float2(23, 43),
					float2((23 - 43)/2f, 0),
					float2(23, 43), float2(0));
			}
		}

		[Test]
		public void StretchUniformToFillUpOnlyTest()
		{
			var panel = new StackPanelScene12();
			using (var root = TestRootPanel.CreateWithChild(panel))
			{
				TestImageLayout(root, int2(1586, 896), panel.Image1, float2(1586, 896),
					float2(0, (896-1586)/2f),
					float2(1586, 896), float2(0));
				TestImageLayout(root, int2(527, 896), panel.Image1, float2(527, 896),
					float2((527 - 896)/2f, 0),
					float2(527, 896), float2(0));
			}
		}

		[Test]
		public void StretchUniformToFillUpOnlySmallTest()
		{
			var panel = new StackPanelScene12();
			using (var root = TestRootPanel.CreateWithChild(panel))
			{
				TestImageLayout(root, int2(563, 39), panel.Image1, float2(563, 39),
					float2(0, (39 - 563)/2f),
					float2(563, 39), float2(0));
				TestImageLayout(root, int2(114, 833), panel.Image1, float2(114, 833),
					float2((114 - 833)/2f, 0),
					float2(114, 833), float2(0));
				TestImageLayout(root, int2(55, 29), panel.Image1, float2(55, 29),
					float2((55 - 256)/2f, (29 - 256)/2f),
					float2(55, 29), float2(0));
				TestImageLayout(root, int2(23, 43), panel.Image1, float2(23, 43),
					float2((23 - 256)/2f, (43 - 256)/2f),
					float2(23, 43), float2(0));
			}
		}

		[Test]
		public void StretchUniformToFillDownOnlyTest()
		{
			var panel = new StackPanelScene13();
			using (var root = TestRootPanel.CreateWithChild(panel))
			{
				TestImageLayout(root, int2(1586, 896), panel.Image1, float2(256, 256),
					float2((1586-256)/2f, (896-256)/2f),
					float2(1586, 896), float2(0));
				TestImageLayout(root, int2(527, 896), panel.Image1, float2(256, 256),
					float2((527-256)/2f, (896-256)/2f),
					float2(527, 896), float2(0));
			}
		}

		[Test]
		public void StretchUniformToFillDownOnlySmallTest()
		{
			var panel = new StackPanelScene13();
			using (var root = TestRootPanel.CreateWithChild(panel))
			{
				TestImageLayout(root, int2(563, 39), panel.Image1, float2(256, 39),
					float2((563 - 256)/2f, (39-256)/2f),
					float2(563, 39), float2(0));
				TestImageLayout(root, int2(114, 833), panel.Image1, float2(114, 256),
					float2((114 - 256)/2f, (833-256)/2f),
					float2(114, 833), float2(0));
				TestImageLayout(root, int2(55, 29), panel.Image1, float2(55, 29),
					float2(0, (29 - 55)/2f),
					float2(55, 29), float2(0));
				TestImageLayout(root, int2(23, 43), panel.Image1, float2(23, 43),
					float2((23 - 43)/2f, 0),
					float2(23, 43), float2(0));
			}
		}
	}
}
