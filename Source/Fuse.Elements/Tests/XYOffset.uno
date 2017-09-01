using Uno;
using Uno.Compiler;
using Uno.Testing;

using FuseTest;

namespace Fuse.Elements.Test
{
	public class XYOffsetTest : TestBase
	{
		static void TestElementLayout(Element element, float2 expectActualPosition, float2 expectActualSize, 
			float tolerance = Assert.ZeroTolerance,
			[CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0, 
			[CallerMemberName] string memberName = "")
		{
			Assert.AreEqual(expectActualSize, element.ActualSize, tolerance, filePath, lineNumber, memberName);
			Assert.AreEqual(expectActualPosition, element.ActualPosition, tolerance, filePath, lineNumber,
				memberName);
		}

		[Test]
		public void Basic()
		{
			var p = new global::UX.XYOffset();
			using (var root = TestRootPanel.CreateWithChild(p, int2(100)))
			{
				TestElementLayout(p.TheY, float2(0,25), float2(100,5));
				TestElementLayout(p.TheX, float2(25,0), float2(5,100));
				TestElementLayout(p.TheOffset, float2(50,50), float2(100,100));
			}
		}
	}
}
