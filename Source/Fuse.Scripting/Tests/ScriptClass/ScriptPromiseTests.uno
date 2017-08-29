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

	public class CustomPanel : Panel
	{
		static CustomPanel()
		{
			ScriptClass.Register(
				typeof(CustomPanel),
				new ScriptPromise<CustomPanel,string,string>("getString", ExecutionThread.MainThread, getString),
				new ScriptPromise<CustomPanel,double,double>("getNumber", ExecutionThread.MainThread, getNumber),
				new ScriptPromise<CustomPanel,TestObject,External>("getObject", ExecutionThread.MainThread, getObject, new ResultConverter().Convert));
		}

		static Future<string> getString(CustomPanel self, object[] args)
		{
			return self.StringFuture;
		}

		static Future<double> getNumber(CustomPanel self, object[] args)
		{
			return self.NumberFuture;
		}

		static Future<TestObject> getObject(CustomPanel self, object[] args)
		{
			return self.ObjectFuture;
		}

		public Future<string> StringFuture { get; set; }
		public Future<double> NumberFuture { get; set; }
		public Future<TestObject> ObjectFuture { get; set; }
	}

	public class ScriptPromiseTests : TestBase
	{
		[Test]
		public void StringTest()
		{
			var child = new UX.BasicTest();
			using (var root = TestRootPanel.CreateWithChild(child))
			{
				child.customPanel.StringFuture = new Promise<string>("this is a string");
				root.StepFrameJS();
				Assert.AreEqual("this is a string", child.Properties.StringResult);
			}
		}

		[Test]
		public void NumberTest()
		{
			var child = new UX.BasicTest();
			using (var root = TestRootPanel.CreateWithChild(child))
			{
				child.customPanel.NumberFuture = new Promise<double>(13.37);
				root.StepFrameJS();
				Assert.AreEqual(13.37, child.Properties.NumberResult);
			}
		}

		[Test]
		public void FailTest()
		{
			var child = new UX.BasicTest();
			using (var root = TestRootPanel.CreateWithChild(child))
			{
				var p = new Promise<double>();
				p.Reject(new Exception("fail"));
				child.customPanel.NumberFuture = p;
				root.StepFrameJS();
				Assert.AreEqual("fail", child.Properties.NumberError);
			}
		}

		[Test]
		public void ObjectTest()
		{
			var child = new UX.BasicTest();
			using (var root = TestRootPanel.CreateWithChild(child))
			{
				var o = new TestObject() { Value = "Hello, World!" };
				var p = new Promise<TestObject>();
				p.Resolve(o);
				child.customPanel.ObjectFuture = p;
				root.StepFrameJS();

				var obs = child.Properties.ObjectResult as Fuse.Reactive.IObservable;
				Assert.AreNotEqual(null, obs);
				Assert.AreEqual(1, obs.Length);

				var result = obs[0] as TestObject;
				Assert.AreNotEqual(null, result);
				Assert.AreEqual(o, result);
			}
		}
	}
}
