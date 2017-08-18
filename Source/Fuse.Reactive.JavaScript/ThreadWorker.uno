using Uno;
using Uno.Platform;
using Uno.Collections;
using Uno.Testing;
using Uno.Threading;
using Fuse.Scripting;

namespace Fuse.Reactive
{
	interface IMirror
	{
		object Reflect(object obj);
	}

	partial class ThreadWorker: IDisposable, IDispatcher, IThreadWorker, IMirror
	{
		IDispatcher IThreadWorker.Dispatcher { get { return this; } }
		Function IThreadWorker.Observable { get { return FuseJS.Observable; } }

		internal static Context CreateContext(IThreadWorker worker)
		{
			if defined(USE_JAVASCRIPTCORE) return new Fuse.Scripting.JavaScriptCore.Context(worker);
			else if defined(USE_V8) return new Fuse.Scripting.V8.Context(worker);
			else if defined(USE_DUKTAPE) return new Fuse.Scripting.Duktape.Context(worker);
			else throw new Exception("No JavaScript VM available for this platform");
		}

		static Scripting.Context _context;
		public Scripting.Context Context { get { return _context; } }

		Function _push, _insertAt, _removeAt;

		public void Push(Scripting.Array arr, object value)
		{
			if (_push == null) _push = (Function)_context.Evaluate("push", "(function(arr, value) { arr.push(value); })");
			_push.Call(arr, value);
		}

		public void InsertAt(Scripting.Array arr, int index, object value)
		{
			if (_insertAt == null) _insertAt = (Function)_context.Evaluate("insertAt", "(function(arr, index, value) { arr.splice(index, 0, value); })");
			_insertAt.Call(arr, index, value);
		}

		public void RemoveAt(Scripting.Array arr, int index)
		{
			if (_removeAt == null) _removeAt = (Function)_context.Evaluate("removeAt", "(function(arr, index) { arr.splice(index, 1); })");
			_removeAt.Call(arr, index);
		}

		static FuseJS.Builtins _fuseJS;
		public static FuseJS.Builtins FuseJS { get { return _fuseJS; } }

		readonly Thread _thread;
		readonly ManualResetEvent _ready = new ManualResetEvent(false);
		readonly ManualResetEvent _idle = new ManualResetEvent(true);
		readonly ManualResetEvent _terminate = new ManualResetEvent(false);

		readonly ConcurrentQueue<Action> _queue = new ConcurrentQueue<Action>();
		readonly ConcurrentQueue<Exception> _exceptionQueue = new ConcurrentQueue<Exception>();

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
			_ready.WaitOne();
			_ready.Dispose();
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
				RunInner();
			}
			catch(Exception e)
			{
				Fuse.Diagnostics.UnknownException( "ThreadWorked failed", e, this );
				_exceptionQueue.Enqueue(e);
			}

			if (_context != null)
				_context.Dispose();
		}

		void RunInner()
		{
			try
			{
				if (_context == null)
				{
					_context = CreateContext(this);
					if (_context == null)
					{
						throw new Exception("Could not create script context");
					}
					UpdateManager.AddAction(CheckAndThrow);

					_fuseJS = new FuseJS.Builtins(_context);
				}
			}
			finally
			{
				_ready.Set();
			}

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

				Action action;
				if (_queue.TryDequeue(out action))
				{
					try
					{
						didAnything = true;
						action();
					}
					catch (Exception e)
					{
						_exceptionQueue.Enqueue(e);
					}
				}

				try
				{
					var activity = _fuseJS.UpdateModules(_context);
					didAnything ||= activity;
				}
				catch (Exception e)
				{
					_exceptionQueue.Enqueue(e);
				}

				var t2 = Uno.Diagnostics.Clock.GetSeconds();

				if (!didAnything)
					_idle.Set();
					
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

		/*
			Throws an exception that was generated on the thread. If there are more than one then the previous
			ones will be reported and the last one thrown.
		*/
		public void CheckAndThrow()
		{
			Exception next = null, prev = null;
			while (_exceptionQueue.TryDequeue(out next))
			{
				if (prev != null)
					Fuse.Diagnostics.UnknownException("Skipped Exception", prev, this);
				prev = next;
			}
			
			if (prev != null)
				throw new WrapException(prev);
		}

		public void Invoke(Action action)
		{
			_idle.Reset();
			_queue.Enqueue(action);
		}

		public class Fence
		{
			ManualResetEvent _signaled = new ManualResetEvent(false);

			public bool IsSignaled { get { return _signaled.WaitOne(0); } }
			public void Wait() { _signaled.WaitOne(); }

			internal void Signal() { _signaled.Set(); }
		}

		public Fence PostFence()
		{
			var f = new Fence();
			Invoke(f.Signal);
			return f;
		}
	}
}
