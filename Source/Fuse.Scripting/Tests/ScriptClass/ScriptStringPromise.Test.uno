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
	public class CustomStringPanel : Panel
	{
		static CustomStringPanel()
		{
			ScriptClass.Register(
				typeof(CustomStringPanel),
				new ScriptPromise<CustomStringPanel,string,string>("getString", ExecutionThread.MainThread, getString));
		}

		static Future<string> getString(Context context, CustomStringPanel self, object[] args)
		{
			return self.StringFuture;
		}

		public Future<string> StringFuture { get; set; }
	}

	public class ScriptStringPromiseTest : TestBase
	{
		[Test]
		public void StringTest()
		{
			var child = new UX.StringBasicTest();
			child.customStringPanel.StringFuture = new Promise<string>("this is a string");
			using (var root = TestRootPanel.CreateWithChild(child))
			{
				while (string.IsNullOrEmpty(child.StringProperties.StringResult))
					root.StepFrameJS();

				Assert.AreEqual("this is a string", child.StringProperties.StringResult);
			}
		}
	}
}
