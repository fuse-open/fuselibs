using Uno;
using Uno.Threading;
using Uno.Testing;
using Uno.Collections;

using Fuse.Reactive;
using Fuse.Scripting;
using Fuse.Controls;
using FuseTest;

namespace Fuse.Scripting.Test
{
	class TestObject
	{
		public string Value { get; set; }
	}

	class ResultConverter
	{
		public External Convert(Context context, TestObject result)
		{
			return new External(result);
		}
	}

	public class CustomObjectPanel : Panel
	{
		static CustomObjectPanel()
		{
			ScriptClass.Register(
				typeof(CustomObjectPanel),
				new ScriptPromise<CustomObjectPanel,TestObject,External>("getObject", ExecutionThread.MainThread, getObject, new ResultConverter().Convert));
		}

		static Future<TestObject> getObject(Context context, CustomObjectPanel self, object[] args)
		{
			return self.ObjectFuture;
		}

		public Future<TestObject> ObjectFuture { get; set; }
	}

	public class ScriptObjectPromiseTest : TestBase
	{
		[Test]
		public void ObjectTest()
		{
			var child = new UX.ObjectBasicTest();
			var p = new Promise<TestObject>();
			child.customObjectPanel.ObjectFuture = p;
			using (var root = TestRootPanel.CreateWithChild(child))
			{
				var o = new TestObject() { Value = "Hello, World!" };
				p.Resolve(o);

				while (!(child.ObjectProperties.ObjectResult is Fuse.Reactive.IObservable))
					root.StepFrameJS();

				var obs = (Fuse.Reactive.IObservable)child.ObjectProperties.ObjectResult;

				while (obs.Length == 0)
					root.StepFrameJS();

				Assert.AreEqual(1, obs.Length);

				var result = obs[0] as TestObject;
				Assert.AreNotEqual(null, result);
				Assert.AreEqual(o, result);
			}
		}
	}
}
