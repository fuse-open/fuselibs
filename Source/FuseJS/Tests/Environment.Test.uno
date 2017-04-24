using Uno;
using Uno.IO;
using Uno.Testing;
using Fuse.Scripting;
using FuseTest;

public class JsTest : TestBase
{
	[Test]
	public void Environment()
	{
		new FuseJS.Environment();
		using (var jsRecorder = new JsTestRecorder())
		{
			var context = jsRecorder.Begin();
			var iOS = defined(iOS) ? "true" : "false";
			var android = defined(android) ? "true" : "false";
			var mobile = defined(mobile) ? "true" : "false";
			var designmode = defined(designmode) ? "true" : "false";

			context.Evaluate("Environment.Test.uno", "var iOS = " + iOS + ";");
			context.Evaluate("Environment.Test.uno", "var Android = " + android + ";");
			context.Evaluate("Environment.Test.uno", "var mobile = " + mobile + ";");
			context.Evaluate("Environment.Test.uno", "var preview = " + designmode + ";");
			var moduleResult = new FileModule(import BundleFile("environment.js")).Evaluate(context, "environment");
			if (moduleResult.Error != null)
				throw moduleResult.Error;

			jsRecorder.End();
		} 
	}
}
