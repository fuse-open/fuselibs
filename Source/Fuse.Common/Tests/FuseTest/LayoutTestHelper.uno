using Uno;
using Uno.Compiler;
using Uno.Collections;
using Uno.Testing;
using Fuse;
using Fuse.Elements;

namespace FuseTest
{
	public class LayoutTestHelper
	{
		public static void TestElementLayout(TestRootPanel root, Element element, int2 rootSize, float2 expectActualSize, float2 expectActualPosition,
			[CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0, [CallerMemberName] string memberName = "")
		{
			root.Layout(rootSize);
			TestElementLayout(element, expectActualSize, expectActualPosition, filePath, lineNumber, memberName);
		}

		public static void TestElementLayout(TestRootPanel root, Element element, int2 rootSize, float2 expectActualSize, float2 expectActualPosition, float tolerancy,
			[CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0, [CallerMemberName] string memberName = "")
		{
			root.Layout(rootSize);
			TestElementLayout(element, expectActualSize, expectActualPosition, tolerancy, filePath, lineNumber, memberName);
		}

		public static void TestElementLayout(Element element, float2 expectActualSize, float2 expectActualPosition,
			[CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0, [CallerMemberName] string memberName = "")
		{
			Assert.AreEqual(expectActualSize, element.ActualSize, Assert.ZeroTolerance, filePath, lineNumber, memberName);
			Assert.AreEqual(expectActualPosition, element.ActualPosition, Assert.ZeroTolerance, filePath, lineNumber, memberName);
		}

		public static void TestElementLayout(Element element, float2 expectActualSize, float2 expectActualPosition, float tolerance,
			[CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0, [CallerMemberName] string memberName = "")
		{
			Assert.AreEqual(expectActualSize, element.ActualSize, tolerance, filePath, lineNumber, memberName);
			Assert.AreEqual(expectActualPosition, element.ActualPosition, tolerance, filePath, lineNumber, memberName);
		}
	}
}
