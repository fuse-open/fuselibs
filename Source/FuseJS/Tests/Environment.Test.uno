using Uno;
using Uno.IO;
using Uno.Testing;
using Fuse.Scripting;
using Fuse.Scripting.JavaScript.Test;
using FuseTest;

public class EnvironmentTest : TestBase
{
	[Test]
	public void Environment()
	{
		JSTest.RunTest(EnvironmentInner);
	}

	void EnvironmentInner(Fuse.Scripting.Context context)
	{
		new FuseJS.Environment();
		var iOS = defined(iOS) ? "true" : "false";
		var android = defined(android) ? "true" : "false";
		var mobile = defined(mobile) ? "true" : "false";
		var designmode = defined(designmode) ? "true" : "false";

		context.Evaluate("Environment.Test.uno", "var iOS = " + iOS + ";");
		context.Evaluate("Environment.Test.uno", "var Android = " + android + ";");
		context.Evaluate("Environment.Test.uno", "var mobile = " + mobile + ";");
		context.Evaluate("Environment.Test.uno", "var preview = " + designmode + ";");
		var moduleResult = new FileModule(import("environment.js")).Evaluate(context, "environment");
		if (moduleResult.Error != null)
			throw moduleResult.Error;
	}
}
