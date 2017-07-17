using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Content;
using Uno.Content.Models;
using Uno.Testing;
using Uno.Testing.Assert;
using FuseTest;

namespace Fuse.Test
{
	public partial class ImageTests : TestBase
	{
		[Test]
		public void StretchNoneTest()
		{
			var panel = new StackPanelScene3();
			_root.Children.Add(panel);

			TestImageLayout(int2(1586, 896), panel.Image1, float2(256, 256),
			float2((1586 - 256)/2f, (896 - 256)/2f),
			float2(1586, 896), float2(0));
			TestImageLayout(int2(123, 171), panel.Image1, float2(123, 171),
			float2((123 - 256)/2f, (171 - 256)/2f),
			float2(123, 171), float2(0));
		}

		[Test]
		public void StretchNoneUpOnlyTest()
		{
			var panel = new StackPanelScene6();
			_root.Children.Add(panel);

			TestImageLayout(int2(1586, 896), panel.Image1, float2(256, 256),
			float2((1586 - 256)/2f, (896 - 256)/2f),
			float2(1586, 896), float2(0));
			TestImageLayout(int2(123, 171), panel.Image1, float2(123, 171),
			float2((123 - 256)/2f, (171 - 256)/2f),
			float2(123, 171), float2(0));
		}

		[Test]
		public void StretchNoneDownOnlyTest()
		{
			var panel = new StackPanelScene7();
			_root.Children.Add(panel);

			TestImageLayout(int2(1586, 896), panel.Image1, float2(256, 256),
			float2((1586 - 256)/2f, (896 - 256)/2f),
			float2(1586, 896), float2(0));
			TestImageLayout(int2(123, 171), panel.Image1, float2(123, 171),
			float2((123 - 256)/2f, (171 - 256)/2f),
			float2(123, 171), float2(0));
		}

		[Test]
		public void StretchNoneStackPanelTest_00()
		{
			var panel = new StackPanelScene14();
			_root.Children.Add(panel);

			TestImageLayout(int2(1586, 896), panel.Image1, float2(256, 256),
			float2((1586 - 256)/2f, 0),
			float2(1586, 256), float2(0));
			TestImageLayout(int2(937, 936), panel.Image1, float2(256, 256),
			float2((937 - 256)/2f, 0),
			float2(937, 256), float2(0));
			TestImageLayout(int2(1383, 137), panel.Image1, float2(256, 256),
			float2((1383 - 256)/2f, 0),
			float2(1383, 256), float2(0));
			TestImageLayout(int2(180, 936), panel.Image1, float2(180, 256),
			float2(-38,0),
			float2(180, 256), float2(0));
		}

		[Test]
		public void StretchNoneStackPanelTest_01()
		{
			var panel = new StackPanelScene15();
			_root.Children.Add(panel);

			TestImageLayout(int2(1586, 896), panel.Image1, float2(256, 256),
			float2(0, (896 - 256)/2f),
			float2(256, 896), float2(0));
			TestImageLayout(int2(937, 936), panel.Image1, float2(256, 256),
			float2(0, (936 - 256)/2f),
			float2(256, 936), float2(0));
			TestImageLayout(int2(1383, 137), panel.Image1, float2(256, 137),
			float2(0,-59.5f),
			float2(256, 137), float2(0));
			TestImageLayout(int2(180, 936), panel.Image1, float2(256, 256),
			float2(0, (936 - 256)/2f),
			float2(256, 936), float2(0));
		}

		[Test]
		public void StretchNoneStackPanelTest09()
		{
			var panel = new StackPanelScene17();
			_root.Children.Add(panel);

			TestImageLayout(int2(821, 936), panel.Image1, float2(60, 20),
			float2((60 - 256)/2f, (20 - 256)/2f),
			float2(60, 20), float2(0, (936 - 20)/2f));
		}
	}
}
