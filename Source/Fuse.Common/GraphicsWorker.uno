using Uno;
using Uno.Threading;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse;

namespace Fuse
{
	[extern(ANDROID) Require("Source.Include", "Uno/Graphics/GLHelper.h")]
	/** Allows dispatching actions on a separate thread with access to a grpahics
		context that shares data with the main graphics context of the @App.
		This is for example used to do asynchronous loading of textures.
	 */
	public static class GraphicsWorker
	{
		public static void Dispatch(Action a)
		{
			if defined(MOBILE)
			{
				Start();
				_work.Enqueue(a);
				_resetEvent.Set();
			}
			else
			{
				// we don't have the nessecary context-stuff to wire up
				// this code for now, so let's just call the action right
				// away
				a();
			}
		}

		static ConcurrentQueue<Action> _work;

		static Thread _thread;

		static AutoResetEvent _resetEvent;

		static extern(iOS) ObjC.Object _workerContext;

		[Foreign(Language.ObjC)]
		extern(iOS) static ObjC.Object CreateContext()
		@{
			return [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:[EAGLContext currentContext].sharegroup];
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) static void SetCurrentContext(ObjC.Object context)
		@{
			[EAGLContext setCurrentContext: context];
		@}

		static void Start()
		{
			if (_thread != null)
				return;

			Fuse.Platform.Lifecycle.Terminating += OnTerminating;

			if defined(iOS)
				_workerContext = CreateContext();

			_work = new ConcurrentQueue<Action>();
			_resetEvent = new AutoResetEvent(false);
			_thread = new Thread(Run);
			_thread.Start();
		}

		static bool _terminating;

		static void OnTerminating(Fuse.Platform.ApplicationState newState)
		{
			_terminating = true;
			_resetEvent.Set();
			_thread.Join();
		}

		static readonly ConcurrentQueue<Exception> _exceptionQueue = new ConcurrentQueue<Exception>();

		static public void DispatchException()
		{
			Exception e;
			if (!_exceptionQueue.TryDequeue(out e))
				throw new Exception("_exceptionQueue mismatch");
			throw new WrapException(e);
		}

		static void Run()
		{
			if defined(Android)
				extern "GLHelper::MakeWorkerThreadContextCurrent()";
			else if defined(iOS)
				SetCurrentContext(_workerContext);

			while (!_terminating)
			{
				if defined(CPLUSPLUS)
					extern "uAutoReleasePool ____pool";

				Action a;
				if (_work.TryDequeue(out a))
				{
					try
					{
						a();
					}
					catch (Exception e)
					{
						Fuse.Diagnostics.UnknownException("GraphicsWorker failed", e, a);
						_exceptionQueue.Enqueue(e);
						UpdateManager.PostAction(DispatchException);
					}
					continue;
				}
				_resetEvent.WaitOne();
			}

			if defined(iOS)
				_workerContext = null;
		}

	}
}
