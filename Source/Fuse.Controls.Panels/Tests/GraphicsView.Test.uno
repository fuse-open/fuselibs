using Uno;
using Uno.Testing;

using FuseTest;
using Fuse.Controls;
using Fuse.Resources;

namespace Fuse.Controls.Panels.Test
{
	public class GraphicsViewTest : TestBase
	{
		[Test]
		[Ignore("https://github.com/fuse-open/fuselibs/issues/671", "Android || iOS")]
		public void GraphicsViewTest1()
		{
			using (var root1 = TestRootPanel.CreateWithChild(new UX.Issue1109.GraphicsView1()))
				Assert.IsTrue(root1.Children[0] is GraphicsView);

			using (var root2 = TestRootPanel.CreateWithChild(new UX.Issue1109.GraphicsView2()))
				Assert.IsTrue(root2.Children[0] is GraphicsView);

			using (var root3 = TestRootPanel.CreateWithChild(new UX.Issue1109.GraphicsView3()))
				Assert.IsTrue(root3.Children[0] is NativeViewHost);

			using (var root4 = TestRootPanel.CreateWithChild(new UX.Issue1109.GraphicsView4()))
				Assert.IsTrue(root4.Children[0] is GraphicsView);
		}
	}
}
