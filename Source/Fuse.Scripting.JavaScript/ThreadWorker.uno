using Uno;
using Uno.Platform;
using Uno.Collections;
using Uno.Testing;
using Uno.Threading;
using Fuse.Scripting;

namespace Fuse.Scripting.JavaScript
{
	interface IMirror
	{
		object Reflect(Scripting.Context context, object obj);
	}

	class ThreadWorker: IDisposable, IThreadWorker
	{
		readonly Thread _thread;

		readonly ManualResetEvent _idle = new ManualResetEvent(true);
		readonly ManualResetEvent _terminate = new ManualResetEvent(false);

		readonly ConcurrentQueue<Action<Scripting.Context>> _queue = new ConcurrentQueue<Action<Scripting.Context>>();

		public ThreadWorker()
		{
			_thread = new Thread(Run);
			if defined(DotNet)
			{
				// TODO: Create a method for canceling the thread safely
				// Threads are by default foreground threads
				// Foreground threads prevents the owner process from exiting, before the thread is safely closed
				// This is a workaround by setting the thread to be a background thread.
				_thread.IsBackground = true;
			}

			_thread.Start();
		}

		void OnTerminating(Fuse.Platform.ApplicationState newState)
		{
			Dispose();
		}

		public void Dispose()
		{
			Fuse.Platform.Lifecycle.Terminating -= OnTerminating;

			_terminate.Set();
			_thread.Join();
			_terminate.Dispose();
		}

		bool _subscribedForClosing;

		void Run()
		{
			try
			{
				using (var context = JSContext.Create())
					RunInner(context);
			}
			catch(Exception e)
			{
				Fuse.Diagnostics.UnknownException( "ThreadWorked failed", e, this );
				DispatchException(e);
			}
		}

		void RunInner(JSContext context)
		{
			double t = Uno.Diagnostics.Clock.GetSeconds();

			while (true)
			{
				if (_terminate.WaitOne(0))
					break;

				if defined(CPLUSPLUS) extern "uAutoReleasePool ____pool";

				if (!_subscribedForClosing)
				{
					if (Uno.Application.Current != null)
					{
						Fuse.Platform.Lifecycle.Terminating += OnTerminating;
						_subscribedForClosing = true;
					}
				}

				bool didAnything = false;

				Action<Scripting.Context> action;
				if (_queue.TryDequeue(out action))
				{
					try
					{
						didAnything = true;
						action(context);
					}
					catch (Exception e)
					{
						DispatchException(e);
					}
				}
				else
					_idle.Set();

				try
				{
					context.FuseJS.UpdateModules(context);
				}
				catch (Exception e)
				{
					DispatchException(e);
				}

				var t2 = Uno.Diagnostics.Clock.GetSeconds();

				if (!didAnything || t2-t > 5)
				{
					Thread.Sleep(1);
					t = t2;
				}
			}
		}

		/**
			Waits for any queued items to finish executing. Used only for testing now.
		*/
		public void WaitIdle()
		{
			_idle.WaitOne();
		}

		class ExceptionClosure
		{
			readonly Exception _exception;

			public ExceptionClosure(Exception exception)
			{
				_exception = exception;
			}

			public void Run()
			{
				throw new WrapException(_exception);
			}
		}

		/*
			Dispatches an exception from the JS-thread to the UI-thread.
		*/
		void DispatchException(Exception e)
		{
			var closure = new ExceptionClosure(e);
			UpdateManager.PostAction(closure.Run);
		}

		public void Invoke(Action<Scripting.Context> action)
		{
			_idle.Reset();
			_queue.Enqueue(action);
		}

		public void Invoke<T>(Uno.Action<Scripting.Context, T> action, T arg0)
		{
			Invoke(new ContextClosureOneArg<T>(action, arg0).Run);
		}

		public void Invoke(Action action)
		{
			Invoke(new ContextIgnoringAction(action).Run);
		}

		public class Fence
		{
			ManualResetEvent _signaled = new ManualResetEvent(false);

			public bool IsSignaled { get { return _signaled.WaitOne(0); } }
			public void Wait() { _signaled.WaitOne(); }

			internal void Signal(Scripting.Context context) { _signaled.Set(); }
		}

		public Fence PostFence()
		{
			var f = new Fence();
			Invoke(f.Signal);
			return f;
		}

		class ContextIgnoringAction
		{
			Uno.Action _action;

			public ContextIgnoringAction(Uno.Action action)
			{
				_action = action;
			}

			public void Run(Scripting.Context context)
			{
				_action();
			}
		}

		class ContextClosureOneArg<T>
		{
			T _arg0;
			Uno.Action<Context, T> _action;

			public ContextClosureOneArg(Uno.Action<Context, T> action, T arg0)
			{
				_action = action;
				_arg0 = arg0;
			}

			public void Run(Context context)
			{
				_action(context, _arg0);
			}
		}
	}
}
