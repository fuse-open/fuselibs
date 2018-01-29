using Uno;
using Uno.Compiler;
using Uno.Testing;
using Uno.Testing.Assert;
using Fuse;
using Fuse.Internal;
using Fuse.Internal.Drawing;
using Fuse.Controls;
using FuseTest;

namespace Fuse.Test
{
	public partial class ImageTest : TestBase
	{
		[Test]
		public void NoTextureSpecified()
		{
			var panel = new StackPanelScene1();
			using (var root = TestRootPanel.CreateWithChild(panel, int2(822)))
			{
				TestImageLayout(root, int2(822), panel.Image1, float2(0), float2(411,0));
			}
		}

		[Test]
		public void Scale9Test01()
		{
			var panel = new Scale9Test01();
			using (var root = TestRootPanel.CreateWithChild(panel))
			{
				TestImageLayout(root, int2(1568, 896), panel.Image1, float2(67), float2((198 - 67)/2f, 0),
					float2(67/48f), float2(198, 67), float2(0));

				TestImageLayout(root, int2(1568, 896), panel.Image2, float2(224, 123), float2(0, 0),
					float2(224/128f, 123/128f), float2(224, 123), float2(0));

				TestImageLayout(root, int2(1568, 896), panel.Image3, float2(1568, 132), float2(0, 0),
					float2(1568/128f, 132/128f), float2(1568, 132), float2(0, 896 - 132));

				TestImageLayout(root, int2(1568, 896), panel.Image4, float2(49, 43), float2(0, 0),
					float2(49/128f, 43/128f), float2(49, 43), float2(0, 0));
			}
		}

		[Test]
		public void Scale9Test02()
		{
			var panel = new Scale9Test02();
			using (var root = TestRootPanel.CreateWithChild(panel, int2(1586, 896)))
			{
				var contentSize = panel.Contents.ActualSize;
				TestImageLayout(root, int2(1586, 896), panel.Image1, contentSize, float2(0),
					contentSize/float2(62,39), contentSize, float2(0));
			}
		}

		/* TODO: Padding is not yet supported
		[Test]
		public void Scale9Test03()
		{
			var panel = new Scale9Test03();
			_root.Children.Add(panel);

			TestImageLayout(int2(307, 402), panel.Image1, float2(224-12-4, 123-7-2), float2(0),
				float2(224, 123), float2((307 - 224)/2f, (402 - 123)/2f));
		}
		*/

		static void TestImageLayout(TestRootPanel root, int2 layout, Image image, float2 drawSize, float2 drawPosition,
			float2 scaling, float2 size, float2 position,
			[CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0, [CallerMemberName] string memberName = "")
		{
			TestImageLayout(root, layout, image, drawSize, drawPosition, size, position,
				filePath, lineNumber, memberName);
			var visual = image;
			Assert.IsTrue(visual != null);
			Assert.AreEqual(scaling, visual._scale, Assert.ZeroTolerance, filePath, lineNumber, memberName); 
		}

		static void TestImageLayout(TestRootPanel root, int2 layout, Image image, float2 drawSize, float2 drawPosition,
			float2 size, float2 position,
			[CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0, [CallerMemberName] string memberName = "")
		{
			TestImageLayout(root, layout, image, drawSize, drawPosition,
				filePath, lineNumber, memberName);
			Assert.AreEqual(size, image.ActualSize, Assert.ZeroTolerance, filePath, lineNumber, memberName);
			Assert.AreEqual(position, image.ActualPosition, Assert.ZeroTolerance, filePath, lineNumber, memberName);
		}

		static void TestImageLayout(TestRootPanel root, int2 layout, Image image, float2 drawSize, float2 drawPosition,
			[CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0, [CallerMemberName] string memberName = "")
		{
			root.Layout(layout);
			var visual = image;
			Assert.IsTrue(visual != null);
			Assert.AreEqual(drawSize, visual._drawSize, Assert.ZeroTolerance, filePath, lineNumber, memberName);
			Assert.AreEqual(drawPosition, visual._origin, Assert.ZeroTolerance, filePath, lineNumber, memberName); 
		}
	}
}
