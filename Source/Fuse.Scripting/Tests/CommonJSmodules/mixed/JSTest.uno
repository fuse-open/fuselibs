using Uno;
using Uno.IO;
using Uno.Testing;
using Fuse.Scripting;
using FuseTest;

public class JsTest : TestBase
{
	[Test]
	public void CommonJS_exactExports()
	{
		using (var jsRecorder = new JsTestRecorder())
		{
			var context = jsRecorder.Begin();
			var moduleResult = new FileModule(import BundleFile("exactExports/main.js")).Evaluate(context, "main");
			if (moduleResult.Error != null)
				throw moduleResult.Error;

			jsRecorder.End();
		}
	}

	[Test]
	public void CommonJS_method()
	{
		using (var jsRecorder = new JsTestRecorder())
		{
			var context = jsRecorder.Begin();
			var moduleResult = new FileModule(import BundleFile("method/main.js")).Evaluate(context, "main");
			if (moduleResult.Error != null)
				throw moduleResult.Error;

			jsRecorder.End();
		}
	}

	[Test]
	public void CommonJS_Missing()
	{
		using (var jsRecorder = new JsTestRecorder())
		{
			var context = jsRecorder.Begin();
			var moduleResult = new FileModule(import BundleFile("missing/main.js")).Evaluate(context, "main");
			if (moduleResult.Error != null)
				throw moduleResult.Error;

			jsRecorder.End();
		}
	}

	[Test]
	public void CommonJS_monkeys()
	{
		using (var jsRecorder = new JsTestRecorder())
		{
			var context = jsRecorder.Begin();
			var moduleResult = new FileModule(import BundleFile("monkeys/main.js")).Evaluate(context, "main");
			if (moduleResult.Error != null)
				throw moduleResult.Error;

			jsRecorder.End();
		}
	}
}
