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
		var test = new JSTest(AbsoluteInner);
		test.WaitOnResults();
	}

	void AbsoluteInner(Fuse.Scripting.Context context)
	{
		var moduleResult = new FileModule(import("absolute/main.js")).Evaluate(context, "main");
		if (moduleResult.Error != null)
			throw moduleResult.Error;	}

	[Test]
	public void Cyclic()
	{
		var test = new JSTest(CyclicInner);
		test.WaitOnResults();
	}

	void CyclicInner(Fuse.Scripting.Context context)
	{
		var moduleResult = new FileModule(import("cyclic/main.js")).Evaluate(context, "main");
		if (moduleResult.Error != null)
			throw moduleResult.Error;
	}

	[Test]
	[Ignore("https://github.com/fusetools/fuselibs-public/issues/679", "Android")]
	public void Determinism()
	{
		var test = new JSTest(DeterminismInner);
		test.WaitOnResults();
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
		var test = new JSTest(RequireDirectoryInner);
		test.WaitOnResults();
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
		var test = new JSTest(DoubleEvaluateInner);
		test.WaitOnResults();
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
		var test = new JSTest(ExactExportsInner);
		test.WaitOnResults();
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
		var test = new JSTest(MethodInner);
		test.WaitOnResults();
	}

	void MethodInner(Fuse.Scripting.Context context)
	{
		var moduleResult = new FileModule(import("method/main.js")).Evaluate(context, "main");
		if (moduleResult.Error != null)
			throw moduleResult.Error;
	}

	[Test]
	[Ignore("https://github.com/fusetools/fuselibs-public/issues/679", "Android")]
	public void Missing()
	{
		var test = new JSTest(MissingInner);
		test.WaitOnResults();
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
		var test = new JSTest(MonkeysInner);
		test.WaitOnResults();
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
		var test = new JSTest(NestedInner);
		test.WaitOnResults();
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
		var test = new JSTest(RelativeInner);
		test.WaitOnResults();
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
		var test = new JSTest(TransitiveInner);
		test.WaitOnResults();
	}

	void TransitiveInner(Fuse.Scripting.Context context)
	{
		var moduleResult = new FileModule(import("transitive/main.js")).Evaluate(context, "main");
		if (moduleResult.Error != null)
			throw moduleResult.Error;
	}
}
