using Uno;
using Uno.UX;
using Uno.Testing;

using FuseTest;

namespace Fuse.Test
{
	public class UxCompilerTest : TestBase
	{
		[Test]
		// Ensure UX names hide Uno ones, refer https://github.com/fusetools/fuselibs-public/issues/911
		public void PropNames()
		{
			var p = new UX.UxCompiler.PropNames();
			using (var r = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "Hello", p.a.t.Value );
			}
		}
	}
}
