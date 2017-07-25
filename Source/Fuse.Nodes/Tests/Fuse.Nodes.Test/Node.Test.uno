using Uno;
using Uno.Testing;

using Fuse;
using FuseTest;

namespace Fuse.Test
{
	public class NodeTest : TestBase
	{
		class MockNode : Node { }
		class MockBinding : Binding { }

		[Test]
		public void UnrootAtRemoval()
		{
			var p = new MockNode();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				var b1 = new MockBinding();
				var b2 = new MockBinding();

				p.Add(b1);
				p.Add(b2);
				Assert.AreNotEqual(null, b1.Parent);
				Assert.AreNotEqual(null, b2.Parent);

				p.Bindings.RemoveAt(1);
				p.Bindings.RemoveAt(0);
				Assert.AreEqual(null, b1.Parent);
				Assert.AreEqual(null, b2.Parent);
			}
		}
	}
}
