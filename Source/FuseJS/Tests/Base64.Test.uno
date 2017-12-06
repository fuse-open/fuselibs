using Uno;
using Uno.IO;
using Uno.Testing;
using Fuse.Scripting;
using Fuse.Scripting.JavaScript.Test;
using FuseTest;

namespace FuseJS.Test
{
	public class Base64Test : TestBase
	{
		[Test]
		public void JavaScriptTests()
		{
			JSTest.RunTest(JavaScriptTestsInner);
		}

		void JavaScriptTestsInner(Fuse.Scripting.Context context)
		{
			new FuseJS.Base64();
			var moduleResult = new FileModule(import("Base64Tests.js")).Evaluate(context, "Base64Tests");
			if (moduleResult.Error != null)
				throw moduleResult.Error;
		}
	}
}
