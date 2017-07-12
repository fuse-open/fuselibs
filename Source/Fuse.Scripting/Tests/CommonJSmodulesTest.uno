using Uno;
using Uno.IO;
using Uno.Testing;
using Fuse.Scripting;
using FuseTest;

public class CommonJSmodules : TestBase
{
	[Test]
	public void Absolute()
	{
		using (var jsRecorder = new JsTestRecorder())
		{
			var context = jsRecorder.Begin();
			var moduleResult = new FileModule(import BundleFile("absolute/main.js")).Evaluate(context, "main");
			if (moduleResult.Error != null)
				throw moduleResult.Error;

			jsRecorder.End();
		}
	}

	[Test]
	public void Cyclic()
	{
		using (var jsRecorder = new JsTestRecorder())
		{
			var context = jsRecorder.Begin();
			var moduleResult = new FileModule(import BundleFile("cyclic/main.js")).Evaluate(context, "main");
			if (moduleResult.Error != null)
				throw moduleResult.Error;

			jsRecorder.End();
		}
	}

	[Test]
	public void Determinism()
	{
		using (var jsRecorder = new JsTestRecorder())
		{
			var context = jsRecorder.Begin();
			var moduleResult = new FileModule(import BundleFile("determinism/main.js")).Evaluate(context, "main");
			if (moduleResult.Error != null)
				throw moduleResult.Error;

			jsRecorder.End();
		}
	}

	[Test]
	public void RequireDirectory()
	{
		using (var jsRecorder = new JsTestRecorder())
		{
			var context = jsRecorder.Begin();
			var moduleResult = new FileModule(import BundleFile("directory/main.js")).Evaluate(context, "main");
			if (moduleResult.Error != null)
				throw moduleResult.Error;

			jsRecorder.End();
		}
	}

	[Test]
	public void DoubleEvaluate()
	{
		using (var jsRecorder = new JsTestRecorder())
		{
			var context = jsRecorder.Begin();
			var moduleResult = new FileModule(import BundleFile("doubleEvaluate/main.js")).Evaluate(context, "main");
			if (moduleResult.Error != null)
				throw moduleResult.Error;

			jsRecorder.End();
		}
	}

	[Test]
	public void ExactExports()
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
	public void Method()
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
	public void Missing()
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
	public void Monkeys()
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

	[Test]
	public void Nested()
	{
		using (var jsRecorder = new JsTestRecorder())
		{
			var context = jsRecorder.Begin();
			var moduleResult = new FileModule(import BundleFile("nested/main.js")).Evaluate(context, "main");
			if (moduleResult.Error != null)
				throw moduleResult.Error;

			jsRecorder.End();
		}
	}

	[Test]
	public void Relative()
	{
		using (var jsRecorder = new JsTestRecorder())
		{
			var context = jsRecorder.Begin();
			var moduleResult = new FileModule(import BundleFile("relative/main.js")).Evaluate(context, "main");
			if (moduleResult.Error != null)
				throw moduleResult.Error;

			jsRecorder.End();
		}
	}

	[Test]
	public void Transitive()
	{
		using (var jsRecorder = new JsTestRecorder())
		{
			var context = jsRecorder.Begin();
			var moduleResult = new FileModule(import BundleFile("transitive/main.js")).Evaluate(context, "main");
			if (moduleResult.Error != null)
				throw moduleResult.Error;

			jsRecorder.End();
		}
	}
}
