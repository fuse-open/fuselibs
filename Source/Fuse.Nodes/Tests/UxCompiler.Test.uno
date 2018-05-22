using Uno;
using Uno.UX;
using Uno.Testing;

using FuseTest;

namespace Fuse.Test
{
	public class UxCompilerTest : TestBase
	{
		[Test]
		// Ensure UX names hide Uno ones, refer https://github.com/fuse-open/fuselibs/issues/911
		public void PropNames()
		{
			var p = new UX.UxCompiler.PropNames();
			using (var r = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "Hello", p.a.t.Value );
			}
		}

		[Test]
		// All Node types should have source information available, so let's make some nodes and double-check that this is set up correctly by the UX compiler
		public void NodeSourceInfo()
		{
			var p = new UX.UxCompiler.NodeSource();
			using (var r = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(1, p.SourceLineNumber);
				Assert.AreEqual("UX/UxCompiler.NodeSource.ux", p.SourceFileName);
				Assert.AreEqual(2, p.P1.SourceLineNumber);
				Assert.AreEqual("UX/UxCompiler.NodeSource.ux", p.P1.SourceFileName);
				Assert.AreEqual(3, p.P2.SourceLineNumber);
				Assert.AreEqual("UX/UxCompiler.NodeSource.ux", p.P2.SourceFileName);
				Assert.AreEqual(4, p.P3.SourceLineNumber);
				Assert.AreEqual("UX/UxCompiler.NodeSource.ux", p.P3.SourceFileName);
			}
		}
	}
}
