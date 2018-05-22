using Uno;
using Uno.UX;
using Uno.Testing;

using Fuse.Controls;
using FuseTest;

namespace Fuse.Reactive.Test
{
	public class JavaScriptTest : TestBase
	{
		[Test]
		public void Names()
		{
			var j = new UX.JavaScript.Names();
			using (var root = TestRootPanel.CreateWithChild(j))
			{
				root.StepFrameJS();
				
				j.callGo.Perform();
				root.StepFrameJS();
				Assert.AreEqual("yes", j.text.Value);
			}
		}
		
		// NOTE: This test is excluded on MSVC since the compiler used for that target apparently
		// don't properly support unicode symbols. We're not using the [Ignore] attribute here
		// since that won't exclude the test during compilation.
		[Test]
		//future-proofing any cleanup of exported names (this uses unusual, but valid JS names)
		//refer to https://github.com/fuse-open/fuselibs/issues/972
		extern(!MSVC) public void ExoticNames()
		{
			var j = new UX.JavaScript.ExoticNames();
			using (var root = TestRootPanel.CreateWithChild(j))
			{
				root.StepFrameJS();
				
				j.callGo.Perform();
				root.StepFrameJS();
				Assert.AreEqual("yes", j.text1.Value);
				Assert.AreEqual("yes", j.text2.Value);
				Assert.AreEqual("yes", j.text3.Value);
			}
		}
	}
}