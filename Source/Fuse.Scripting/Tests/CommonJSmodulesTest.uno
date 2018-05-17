using Uno;
using Uno.IO;
using Uno.Testing;
using Fuse.Scripting;
using Fuse.Scripting.Test;
using Fuse.Scripting.JavaScript.Test;
using FuseTest;

public class CommonJSmodules : TestBase
{
	[Test]
	public void Absolute()
	{
		JSTest.RunTest(AbsoluteInner);
	}

	void AbsoluteInner(Fuse.Scripting.Context context)
	{
		var moduleResult = new FileModule(import("absolute/main.js")).Evaluate(context, "main");
		if (moduleResult.Error != null)
			throw moduleResult.Error;	}

	[Test]
	public void Cyclic()
	{
		JSTest.RunTest(CyclicInner);
	}

	void CyclicInner(Fuse.Scripting.Context context)
	{
		var moduleResult = new FileModule(import("cyclic/main.js")).Evaluate(context, "main");
		if (moduleResult.Error != null)
			throw moduleResult.Error;
	}

	[Test]
	[Ignore("https://github.com/fuse-open/fuselibs/issues/679", "Android && USE_V8")]
	public void Determinism()
	{
		JSTest.RunTest(DeterminismInner);
	}

	void DeterminismInner(Fuse.Scripting.Context context)
	{
		var moduleResult = new FileModule(import("determinism/main.js")).Evaluate(context, "main");
		if (moduleResult.Error != null)
			throw moduleResult.Error;
	}

	[Test]
	public void RequireDirectory()
	{
		JSTest.RunTest(RequireDirectoryInner);
	}

	void RequireDirectoryInner(Fuse.Scripting.Context context)
	{
		var moduleResult = new FileModule(import("directory/main.js")).Evaluate(context, "main");
		if (moduleResult.Error != null)
			throw moduleResult.Error;
	}

	[Test]
	public void DoubleEvaluate()
	{
		JSTest.RunTest(DoubleEvaluateInner);
	}

	void DoubleEvaluateInner(Fuse.Scripting.Context context)
	{
		var moduleResult = new FileModule(import("doubleEvaluate/main.js")).Evaluate(context, "main");
		if (moduleResult.Error != null)
			throw moduleResult.Error;
	}

	[Test]
	public void ExactExports()
	{
		JSTest.RunTest(ExactExportsInner);
	}


	void ExactExportsInner(Fuse.Scripting.Context context)
	{
		var moduleResult = new FileModule(import("exactExports/main.js")).Evaluate(context, "main");
		if (moduleResult.Error != null)
			throw moduleResult.Error;
	}

	[Test]
	public void Method()
	{
		JSTest.RunTest(MethodInner);
	}

	void MethodInner(Fuse.Scripting.Context context)
	{
		var moduleResult = new FileModule(import("method/main.js")).Evaluate(context, "main");
		if (moduleResult.Error != null)
			throw moduleResult.Error;
	}

	[Test]
	[Ignore("https://github.com/fuse-open/fuselibs/issues/679", "Android && USE_V8")]
	public void Missing()
	{
		JSTest.RunTest(MissingInner);
	}

	void MissingInner(Fuse.Scripting.Context context)
	{
		var moduleResult = new FileModule(import("missing/main.js")).Evaluate(context, "main");
		if (moduleResult.Error != null)
			throw moduleResult.Error;
	}

	[Test]
	public void Monkeys()
	{
		JSTest.RunTest(MonkeysInner);
	}

	void MonkeysInner(Fuse.Scripting.Context context)
	{
		var moduleResult = new FileModule(import("monkeys/main.js")).Evaluate(context, "main");
		if (moduleResult.Error != null)
			throw moduleResult.Error;
	}

	[Test]
	public void Nested()
	{
		JSTest.RunTest(NestedInner);
	}

	void NestedInner(Fuse.Scripting.Context context)
	{
		var moduleResult = new FileModule(import("nested/main.js")).Evaluate(context, "main");
		if (moduleResult.Error != null)
			throw moduleResult.Error;
	}

	[Test]
	public void Relative()
	{
		JSTest.RunTest(RelativeInner);
	}

	void RelativeInner(Fuse.Scripting.Context context)
	{
		var moduleResult = new FileModule(import("relative/main.js")).Evaluate(context, "main");
		if (moduleResult.Error != null)
			throw moduleResult.Error;
	}

	[Test]
	public void Transitive()
	{
		JSTest.RunTest(TransitiveInner);
	}

	void TransitiveInner(Fuse.Scripting.Context context)
	{
		var moduleResult = new FileModule(import("transitive/main.js")).Evaluate(context, "main");
		if (moduleResult.Error != null)
			throw moduleResult.Error;
	}
}
