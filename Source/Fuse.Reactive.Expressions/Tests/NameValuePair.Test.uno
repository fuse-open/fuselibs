using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Testing;

using Fuse.Controls;
using Fuse.Navigation;
using FuseTest;

namespace Fuse.Reactive.Test
{
	public class NameValuePair : TestBase
	{
		[Test]
		public void Basics()
		{
			var e = new UX.NameValuePair();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual("(boo: False)", e.t.Value);
				e.flip.Perform();
				root.StepFrameJS();
				Assert.AreEqual("(bar: fooTrue)", e.t.Value);
				Assert.AreEqual("123", e.tbar.Value);
				Assert.AreEqual("456", e.tfoo.Value);
			}
		}
	}
}
