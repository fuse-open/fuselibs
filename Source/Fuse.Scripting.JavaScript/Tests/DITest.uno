using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Testing;

using Fuse.Controls;
using Fuse.Navigation;
using FuseTest;

namespace Fuse.Reactive.Test
{
	public class DITest : TestBase
	{
		[Test]
		public void DIBasics()
		{
			var e = new UX.DependencyInjection();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual("30", e.p1.t1.Value);
				Assert.AreEqual("1", e.counter.Value);

				e.ChangeProp.Perform();
				root.StepFrameJS();
				Assert.AreEqual("35", e.p1.t1.Value);
				Assert.AreEqual("2", e.counter.Value);
			}
		}
	}
}
