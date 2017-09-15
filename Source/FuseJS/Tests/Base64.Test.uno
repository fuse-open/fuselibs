using Uno;
using Uno.IO;
using Uno.Testing;
using Fuse.Scripting;
using FuseTest;

namespace FuseJS.Test
{
	public class Base64Test : TestBase
	{
		[Test]
		public void JavaScriptTests()
		{
			new FuseJS.Base64();
			using (var jsRecorder = new JsTestRecorder())
			{
				var context = jsRecorder.Begin();
				var moduleResult = new FileModule(import("Base64Tests.js")).Evaluate(context, "Base64Tests");
				if (moduleResult.Error != null)
					throw moduleResult.Error;

				jsRecorder.End();
			}
		}
	}
}
