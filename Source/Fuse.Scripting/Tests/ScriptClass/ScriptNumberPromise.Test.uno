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
	public class CustomNumberPanel : Panel
	{
		static CustomNumberPanel()
		{
			ScriptClass.Register(
				typeof(CustomNumberPanel),
				new ScriptPromise<CustomNumberPanel,double,double>("getNumber", ExecutionThread.MainThread, getNumber));
		}

		static Future<double> getNumber(Context context, CustomNumberPanel self, object[] args)
		{
			return self.NumberFuture;
		}

		public Future<double> NumberFuture { get; set; }
	}

	public class ScriptNumberPromiseTest : TestBase
	{
		[Test]
		public void NumberTest()
		{
			var child = new UX.NumberBasicTest();
			child.customNumberPanel.NumberFuture = new Promise<double>(13.37);
			using (var root = TestRootPanel.CreateWithChild(child))
			{

				while (child.NumberProperties.NumberResult < 0)
					root.StepFrameJS();

				Assert.AreEqual(13.37, child.NumberProperties.NumberResult);
			}
		}

		[Test]
		public void FailTest()
		{
			var child = new UX.NumberBasicTest();
			var p = new Promise<double>();
			child.customNumberPanel.NumberFuture = p;
			using (var root = TestRootPanel.CreateWithChild(child))
			{
				p.Reject(new Exception("fail"));

				while (string.IsNullOrEmpty(child.NumberProperties.NumberError))
					root.StepFrameJS();

				Assert.AreEqual("fail", child.NumberProperties.NumberError);
			}
		}
	}
}
