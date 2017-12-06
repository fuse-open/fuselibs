using Uno;
using Uno.UX;
using Uno.Testing;
using Uno.Compiler;
using Uno.Collections;
using Uno.Text;
using Uno.Threading;

using Fuse.Reactive;
using Fuse.Scripting;

namespace Fuse.Scripting.JavaScript.Test
{
	// A Copy of Testing's Assert that dispatched to the JS thread, caches the results and can
	// wait safely until the results are ready
	public class JSTest
	{
		readonly ManualResetEvent _testComplete = new ManualResetEvent(false);
		readonly Action<Fuse.Scripting.Context> _test;
		readonly List<Exception> _failures = new List<Exception>();

		JSTest(Action<Fuse.Scripting.Context> test)
		{
			Fuse.Reactive.JavaScript.EnsureVMStarted();
			_test = test;
			Fuse.Reactive.JavaScript.Worker.Invoke(TestBodyWrapper);
		}

		void AddTestToJSContext(Fuse.Scripting.Context context)
		{
			var f = context.Evaluate("", "(function(obj, assert) { obj['test'] = { assert: function(exp, msg) { try { assert(Boolean(exp ? 1 : 0), msg); } catch(e) { assert(0, 'Error: ' + e); } } }; } )") as Fuse.Scripting.Function;
			f.Call(context, context.GlobalObject, (Callback)JSAssertCallback);
		}

		object JSAssertCallback(Fuse.Scripting.Context context, object[] args)
		{
			var result = false;
			if(args.Length > 0)
				result = Fuse.Marshal.ToBool(args[0]);

			var msg = "Uknown JS assertion failure";
			if(args.Length > 1)
				msg = (string)args[1];

			if (!result)
				_failures.Add(new Exception(msg));

			return null;
		}

		void TestBodyWrapper(Fuse.Scripting.Context context)
		{
			AddTestToJSContext(context);
			try
			{
				_test(context);
			}
			catch (Exception e)
			{
				_failures.Add(e);
			}
			_testComplete.Set();
		}

		void WaitOnResults()
		{
			_testComplete.WaitOne();

			foreach (var f in _failures)
			{
				throw f;
			}
		}

		public static void RunTest(Action<Fuse.Scripting.Context> method)
		{
			var test = new JSTest(method);
			test.WaitOnResults();
		}
	}
}
