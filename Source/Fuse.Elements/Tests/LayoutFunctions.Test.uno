using Uno;
using Uno.Compiler;
using Uno.Testing;

using FuseTest;

namespace Fuse.Elements.Test
{
	public class LayoutFunctionsTest : TestBase
	{
		[Test]
		//https://github.com/fusetools/fuselibs/issues/4189
		public void Issue4189()
		{
			var p = new global::UX.LayoutFunctions.Issue4189();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrame();
				var b = p.FindNodeByName("b") as Element;
				Assert.AreEqual(float2(10,20), b.ActualPosition);
				Assert.AreEqual(float2(300,400), b.ActualSize);
				
				Assert.AreEqual(float2(10,20), p.c.ActualPosition);
				Assert.AreEqual(float2(300,400), p.c.ActualSize);
				
				var d = p.FindNodeByName("d") as Element;
				Assert.AreEqual(float2(10,20), b.ActualPosition);
				Assert.AreEqual(float2(300,400), b.ActualSize);
			}
		}
	}
}
