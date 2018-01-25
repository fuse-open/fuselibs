using Uno;
using Uno.UX;
using Uno.Testing;

using FuseTest;

namespace Fuse.Reactive.Bindings.Test
{
	public class DataTest : TestBase
	{
		[Test]
		public void ExcludeJS()
		{
			var p = new UX.Data.ExcludeJS();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual("hi", GetRecursiveText(p));
			}
		}
	}
}
