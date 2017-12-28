using Uno;
using Uno.UX;
using Uno.Testing;

using Fuse.Reactive;

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
		
		[Test]
		public void ContextRef()
		{
			var p = new UX.With.ContextRef();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				//in the second item there is no data yet, it should not resovle to the `value` in the Each item
				Assert.AreEqual("A", GetText(p));
			}
		}
	}
}
