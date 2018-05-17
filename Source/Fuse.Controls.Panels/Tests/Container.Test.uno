using Uno;
using Uno.Testing;

using FuseTest;
using Fuse.Controls;
using Fuse.Resources;

namespace Fuse.Controls.Panels.Test
{
	public class ContainerTest : TestBase
	{
		[Test]
		public void IssuePublic53()
		{
			//https://github.com/fuse-open/fuselibs/issues/53
			var c = new UX.IssuePublic53();
			using (var root = TestRootPanel.CreateWithChild(c))
			{
				// just creating this should be enough to show that this works
			}
		}

		[Test]
		public void SubtreeNodes()
		{
			var c = new UX.ContainerTest();
			using (var root = TestRootPanel.CreateWithChild(c))
			{
				Assert.IsTrue(c.container.SubtreeNodes.Contains(c.bluepanel));
				Assert.IsTrue(c.container.SubtreeNodes.Contains(c.container.foo));

				Assert.IsTrue(c.container.Children.Contains(c.container.bar));
				Assert.IsFalse(c.container.Children.Contains(c.bluepanel));
				Assert.IsFalse(c.container.Children.Contains(c.container.foo));

				Assert.IsTrue(c.container.innerPanel.Children.Contains(c.bluepanel));
				Assert.IsTrue(c.container.innerPanel.Children.Contains(c.container.foo));

				c.container.Subtree = c.container.other;

				Assert.IsFalse(c.container.innerPanel.Children.Contains(c.bluepanel));
				Assert.IsFalse(c.container.innerPanel.Children.Contains(c.container.foo));

				Assert.IsTrue(c.container.other.Children.Contains(c.bluepanel));
				Assert.IsTrue(c.container.other.Children.Contains(c.container.foo));
			}
		}
	}
}
