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

		public static void On(Context context, Action<Scripting.Context> action)
		{
			if (_initialized)
			{
				action(context);
			}
			else
			{
				UpdateManager.Dispatcher.Invoke(new Closure(context.ThreadWorker, action).Run);
			}
		}

		internal static void Reset()
		{
			_initialized = false;
		}

		class Closure
		{
			readonly IThreadWorker _worker;
			readonly Action<Scripting.Context> _action;

			public Closure(IThreadWorker worker, Action<Scripting.Context> action)
			{
				_worker = worker;
				_action = action;
			}

			public void Run()
			{
				_worker.Invoke(RunJS);
			}

			void RunJS(Scripting.Context context)
			{
				_initialized = true;
				_action(context);
			}
		}
	}
}
