using Uno;
using Uno.UX;
using Uno.Testing;

using FuseTest;

namespace Fuse.Reactive.Test
{
	public class ObjectFunctionTest : TestBase
	{
		[Test]
		public void ObjectFunc()
		{
			var p = new UX.ObjectFunction();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual("10", p.ta.Value);
				Assert.AreEqual("lol", p.tb.Value);
			}
		}

	}
}

