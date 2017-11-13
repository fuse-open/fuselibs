using Uno;
using Uno.Testing;
using Uno.Threading;
using Uno.Collections;

using Fuse;
using Fuse.Reactive;
using Fuse.Scripting;
using FuseTest;

public class MyScriptClass : Node
{
	static MyScriptClass()
	{
		ScriptClass.Register(typeof(MyScriptClass),
			new ScriptMethod<MyScriptClass>("jsThreadMethod", jsThreadMethod),
			new ScriptMethod<MyScriptClass>("uiThreadMethod", uiThreadMethod),
			);
	}

	public int JSThreadFuncCalls { get; private set; }
	static object jsThreadMethod(Context c, MyScriptClass self, object[] args)
	{
		self.JSThreadFuncCalls = self.JSThreadFuncCalls + 1;

		Assert.AreEqual(4, args.Length);
		Assert.AreEqual("foo", args[0]);

		// validate object-argument
		Assert.IsTrue(args[1] is Fuse.Scripting.Object);
		var obj = (Fuse.Scripting.Object)args[1];
		Assert.IsTrue(obj.ContainsKey("foo"));
		Assert.AreEqual("bar", obj["foo"]);

		// validate array-argument
		Assert.IsTrue(args[2] is Fuse.Scripting.Array);
		var arr = (Fuse.Scripting.Array)args[2];
		Assert.AreEqual(2, arr.Length);
		Assert.AreEqual("foo", arr[0]);
		Assert.AreEqual("bar", arr[1]);

		// validate function-argument
		Assert.IsTrue(args[3] is Fuse.Scripting.Function);

		return "baz";
	}

	public int UIThreadFuncCalls { get; private set; }
	static void uiThreadMethod(MyScriptClass self, object[] args)
	{
		self.UIThreadFuncCalls = self.UIThreadFuncCalls + 1;

		Assert.AreEqual(4, args.Length);
		Assert.AreEqual("foo", args[0]);

		// validate object-argument
		Assert.IsFalse(args[1] is Fuse.Scripting.Object);
		Assert.IsTrue(args[1] is IObject);
		var obj = (IObject)args[1];
		Assert.IsTrue(obj.ContainsKey("foo"));
		Assert.AreEqual("bar", obj["foo"]);

		// validate array-argument
		Assert.IsFalse(args[2] is Fuse.Scripting.Array);
		Assert.IsTrue(args[2] is IArray);
		var arr = (IArray)args[2];
		Assert.AreEqual(2, arr.Length);
		Assert.AreEqual("foo", arr[0]);
		Assert.AreEqual("bar", arr[1]);

		// validate function-argument
		Assert.IsFalse(args[3] is Fuse.Scripting.Function);
		Assert.IsTrue(args[3] is IEventHandler);
	}
}


namespace Fuse.Scripting.Test
{
	public class ScriptMethodTest : TestBase
	{
		[Test]
		public void JSThreadMethod()
		{
			var p =  new UX.ScriptMethod();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();

				Assert.AreEqual(0, p.ScriptClass.JSThreadFuncCalls);
				p.CallJSThreadMethod.Perform();

				// simply waiting should be sufficient for methods on the JS thread
				var fence = Fuse.Reactive.JavaScript.Worker.PostFence();
				while (!fence.IsSignaled)
					Thread.Sleep(100);

				Assert.AreEqual(1, p.ScriptClass.JSThreadFuncCalls);

				root.MultiStepFrameJS(2); // ensure any exceptions have been thrown
			}
		}

		[Test]
		public void UIThreadMethod()
		{
			var p =  new UX.ScriptMethod();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();

				Assert.AreEqual(0, p.ScriptClass.UIThreadFuncCalls);
				p.CallUIThreadMethod.Perform();

				// sleeping should *not* cause the function to run
				Thread.Sleep(100);
				Assert.AreEqual(0, p.ScriptClass.UIThreadFuncCalls);

				// ...but StepFrameJS should
				root.StepFrameJS();
				Assert.AreEqual(1, p.ScriptClass.UIThreadFuncCalls);

				root.MultiStepFrameJS(2); // ensure any exceptions have been thrown
			}
		}
	}
}
