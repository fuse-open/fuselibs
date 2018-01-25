using Uno;
using Uno.Testing;
using Uno.Testing.Assert;
using FuseTest;

namespace Fuse.Test
{
	public partial class ImageTest : TestBase
	{
		[Test]
		public void StretchFillTest()
		{
			var panel = new StackPanelScene2();
			using (var root = TestRootPanel.CreateWithChild(panel))
			{
				TestImageLayout(root, int2(300, 200), panel.Image1, float2(300, 200), float2(0),
					float2(300, 200), float2(0));
				TestImageLayout(root, int2(300, 200), panel.Image2, float2(300, 200), float2(0),
					float2(300, 200), float2(0));
			}
		}

		[Test]
		public void StretchFillUpOnlyTest()
		{
			var panel = new StackPanelScene8();
			using (var root = TestRootPanel.CreateWithChild(panel))
			{
				TestImageLayout(root, int2(861, 353), panel.Image1, float2(861, 353), float2(0));
				TestImageLayout(root, int2(352, 530), panel.Image1, float2(352, 530), float2(0));
			}
		}

		[Test]
		public void StretchFillUpOnlySmallTest()
		{
			var panel = new StackPanelScene8();
			using (var root = TestRootPanel.CreateWithChild(panel))
			{
				TestImageLayout(root, int2(128, 72), panel.Image1, float2(128, 72),
					float2((128 - 256)/2f, (72 - 256)/2f),
					float2(1, 1), float2(128, 72), float2(0));
				TestImageLayout(root, int2(77, 122), panel.Image1, float2(77, 122),
					float2((77 - 256)/2f, (122 - 256)/2f),
					float2(1, 1), float2(77, 122), float2(0));
			}
		}

		[Test]
		public void StretchFillDownOnlyTest()
		{
			var panel = new StackPanelScene9();
			using (var root = TestRootPanel.CreateWithChild(panel))
			{
				TestImageLayout(root, int2(675, 317), panel.Image1, float2(256, 256),
					float2((675 - 256)/2f, (317 - 256)/2f),
					float2(675, 317), float2(0));
				TestImageLayout(root, int2(352, 530), panel.Image1, float2(256, 256),
					float2((352 - 256)/2f, (530 - 256)/2f),
					float2(352, 530), float2(0));
			}
		}

		[Test]
		public void StretchFillDownOnlySmallTest()
		{
			var panel = new StackPanelScene9();
			using (var root = TestRootPanel.CreateWithChild(panel))
			{
				TestImageLayout(root, int2(128, 72), panel.Image1, float2(128, 72),
					float2(0), float2(128, 72)/float2(256),
					float2(128, 72), float2(0));
				TestImageLayout(root, int2(77, 122), panel.Image1, float2(77, 122),
					float2(0), float2(77, 122)/float2(256),
					float2(77, 122), float2(0));
			}
		}
	}
}
