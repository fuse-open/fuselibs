using Uno;
using Uno.Compiler;
using Uno.Testing;

using FuseTest;

namespace Fuse.Elements.Test
{
	public class XYOffsetTest : TestBase
	{
		static void TestElementLayout(Element element, float2 expectActualPosition, float2 expectActualSize, 
			float tolerance = float.ZeroTolerance,
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
			var root = new TestRootPanel();
			var p = new global::UX.XYOffset();
			root.Children.Add(p);
			
			root.Layout(int2(100));
			TestElementLayout(p.TheY, float2(0,25), float2(100,5));
			TestElementLayout(p.TheX, float2(25,0), float2(5,100));
			TestElementLayout(p.TheOffset, float2(50,50), float2(100,100));
		}
	}
}
