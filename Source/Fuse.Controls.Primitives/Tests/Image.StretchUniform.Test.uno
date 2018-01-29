using Uno;
using Uno.Testing;
using Uno.Testing.Assert;
using FuseTest;

namespace Fuse.Test
{
	public partial class ImageTest : TestBase
	{
		[Test]
		public void StretchUniformTest()
		{
			var panel = new StackPanelScene4();
			using (var root = TestRootPanel.CreateWithChild(panel))
			{
				TestImageLayout(root, int2(1586, 896), panel.Image1, float2(896), float2((1586-896)/2f, 0),
					float2(1586, 896), float2(0));
				TestImageLayout(root, int2(1586, 896), panel.Image2, float2(896), float2((1586-896)/2f, 0),
					float2(1586, 896), float2(0));

				TestImageLayout(root, int2(114, 833), panel.Image1, float2(114), float2(0, (833-114)/2f),
					float2(114, 833), float2(0));
				TestImageLayout(root, int2(114, 833), panel.Image2, float2(114), float2(0, (833-114)/2f),
					float2(114, 833), float2(0));
			}
		}

		[Test]
		public void StretchUniformSmallTest()
		{
			var panel = new StackPanelScene4();
			using (var root = TestRootPanel.CreateWithChild(panel))
			{
				TestImageLayout(root, int2(563, 39), panel.Image1, float2(39), float2((563-39)/2f, 0),
					float2(563, 39), float2(0));
				TestImageLayout(root, int2(563, 39), panel.Image2, float2(39), float2((563-39)/2f, 0),
					float2(563, 39), float2(0));

				TestImageLayout(root, int2(55, 29), panel.Image1, float2(29), float2((55-29)/2f, 0),
					float2(55, 29), float2(0));
				TestImageLayout(root, int2(55, 29), panel.Image2, float2(29), float2((55-29)/2f, 0),
					float2(55, 29), float2(0));

				TestImageLayout(root, int2(23, 43), panel.Image1, float2(23), float2(0, (43-23)/2f),
					float2(23, 43), float2(0));
				TestImageLayout(root, int2(23, 43), panel.Image2, float2(23), float2(0, (43-23)/2f),
					float2(23, 43), float2(0));
			}
		}

		[Test]
		public void StretchUniformUpOnlyTest()
		{
			var panel = new StackPanelScene10();
			using (var root = TestRootPanel.CreateWithChild(panel))
			{
				TestImageLayout(root, int2(1586, 896), panel.Image1, float2(896), float2((1586-896)/2f, 0),
					float2(1586, 896), float2(0));
				TestImageLayout(root, int2(527, 896), panel.Image1, float2(527), float2(0, (896-527)/2f),
					float2(527, 896), float2(0));
			}
		}

		[Test]
		public void StretchUniformUpOnlySmallTest()
		{
			var panel = new StackPanelScene10();
			using (var root = TestRootPanel.CreateWithChild(panel))
			{
				TestImageLayout(root, int2(563, 39), panel.Image1, float2(256, 39),
					float2((563-256)/2f, (39-256)/2f),
					float2(563, 39), float2(0));
				TestImageLayout(root, int2(114, 833), panel.Image1, float2(114, 256),
					float2((114-256)/2f, (833-256)/2f),
					float2(114, 833), float2(0));
				TestImageLayout(root, int2(55, 29), panel.Image1, float2(55, 29),
					float2((55-256)/2f, (29-256)/2f),
					float2(55, 29), float2(0));
				TestImageLayout(root, int2(23, 43), panel.Image1, float2(23, 43),
					float2((23-256)/2f, (43-256)/2f),
					float2(23, 43), float2(0));
			}
		}

		[Test]
		public void StretchUniformDownOnlyTest()
		{
			var panel = new StackPanelScene11();
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
		public void StretchUniformDownOnlySmallTest()
		{
			var panel = new StackPanelScene11();

			using (var root = TestRootPanel.CreateWithChild(panel, int2(563, 39)))
			{
				TestImageLayout(root, int2(563, 39), panel.Image1, float2(39),
					float2((563-39)/2f, 0),
					float2(563, 39), float2(0));
				TestImageLayout(root, int2(114, 833), panel.Image1, float2(114),
					float2(0, (833-114)/2f),
					float2(114, 833), float2(0));
				TestImageLayout(root, int2(55, 29), panel.Image1, float2(29),
					float2((55-29)/2f, 0),
					float2(55, 29), float2(0));
				TestImageLayout(root, int2(23, 43), panel.Image1, float2(23),
					float2(0, (43-23)/2f),
					float2(23, 43), float2(0));
			}
		}
	}
}
