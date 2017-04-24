using Uno;
using Uno.IO;
using Uno.Testing;
using Fuse.Scripting;
using FuseTest;

public class JsTest : TestBase
{
	[Test]
	public void CommonJS_Relative()
	{
		using (var jsRecorder = new JsTestRecorder())
		{
			var context = jsRecorder.Begin();
			var moduleResult = new FileModule(import BundleFile("main.js")).Evaluate(context, "main");
			if (moduleResult.Error != null)
				throw moduleResult.Error;

			jsRecorder.End();
		}
	}
}
