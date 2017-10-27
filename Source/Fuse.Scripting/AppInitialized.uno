using Uno.Threading;
using Uno;

namespace Fuse.Scripting
{
	/** Get a callback when we deem the app to be initialized.

		This point in time comes some time after the app's "top-level",
		i.e. stemming from the initial layout, JS code has run. This is
		achieved by dispatching an action onto the UI thread, run after
		layout is done. The action in turn dispatches an action back to
		the JS thread, which means that it runs after any JS dispatched
		during layout is run.
	*/
	static class AppInitialized
	{
		static bool _initialized;

		public static void On(IThreadWorker worker, Action action)
		{
			if (_initialized)
			{
				action();
			}
			else
			{
				UpdateManager.Dispatcher.Invoke(new Closure(worker, action).Run);
			}
		}

		internal static void Reset()
		{
			_initialized = false;
		}

		class Closure
		{
			readonly IThreadWorker _worker;
			readonly Action _action;

			public Closure(IThreadWorker worker, Action action)
			{
				_worker = worker;
				_action = action;
			}

			public void Run()
			{
				_worker.Invoke<Action>(RunJS, _action);
			}

			static void RunJS(Scripting.Context context, Action action)
			{
				_initialized = true;
				action();
			}
		}
	}
}
