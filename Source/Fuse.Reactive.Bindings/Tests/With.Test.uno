using Uno;
using Uno.Testing;

using Fuse;

using FuseTest;

namespace Fuse.Test
{
	public class WithTest : TestBase
	{
		[Test]
		// Updates to context itself need to be seen
		//https://github.com/fusetools/fuselibs-public/issues/888
		public void ContextChange()
		{
			var p = new UX.With.ContextChange();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual("Hello", GetText(p));
			}
		}
	}
}
