using Uno.Collections;
using Uno.Threading;
using Uno;

namespace Fuse.Scripting
{
	/** A NativeModule that's an instance of @EventEmitter.
	*/
	public class NativeEventEmitterModule : NativeModule
	{
		readonly object[] _eventNames;
		readonly List<Tuple<object, Scripting.Callback>> _listeningCallbacks = new List<Tuple<object, Scripting.Callback>>();
		Scripting.Object _this;
		bool _initialized;
		Context _context;
		readonly bool _queueEventsBeforeInit;
		readonly object _mutex = new object(); // Guards _queuedEvents, _initialized and, _listeningCallbacks
		readonly Queue<Action<Context, Scripting.Object>> _queuedEvents = new Queue<Action<Context, Scripting.Object>>();

		/** Create a new NativeEventEmitterModule.

			@param queueEventsBeforeInit Determines whether any events that are triggered before the initial layout of the application is done should be cached and triggered after layout is done such that any listeners have the chance to attach.
			@param eventNames Determines what event names this EventEmitter allows.
		*/
		public NativeEventEmitterModule(bool queueEventsBeforeInit, params object[] eventNames)
		{
			_queueEventsBeforeInit = queueEventsBeforeInit;
			_eventNames = eventNames;
			Reset += ResetListeners;
		}

		// Called when all JavaScript nodes are unrooted: i.e. on preview reset
		void ResetListeners(object sender, EventArgs eventArgs)
		{
			lock (_mutex)
			{
				_initialized = false;
				_queuedEvents.Clear();
			}

			if (_context != null)
				_context.ThreadWorker.Invoke(ResetListenersJS);
		}

		void ResetListenersJS(Scripting.Context context)
		{
			_this.CallMethod(context, "removeAllListeners");
			// Reconnect any callbacks set from native code
			lock (_mutex)
				foreach (var l in _listeningCallbacks)
					Dispatch(new OnClosure(l.Item1, l.Item2).On, true);
			AppInitialized.On(context, OnAppInitialized);
		}

		override object CreateExportsObject(Context c)
		{
			_context = c;
			_this = EventEmitterModule.GetConstructor(c).Construct(c, _eventNames);

			AppInitialized.On(c, OnAppInitialized);

			return _this;
		}

		void OnAppInitialized(Context c)
		{
			lock (_mutex)
			{
				_initialized = true;
				while (_queuedEvents.Count > 0)
				{
					_queuedEvents.Dequeue()(_context, _this);
				}
			}
		}

		/** Call `emit` with the given arguments on the underlying JS EventEmitter.

			The `emit` action is dispatched to the JS thread.
		*/
		protected void Emit(params object[] args)
		{
			Dispatch(new EmitClosure(args).Emit);
		}

		/** Call `emit` on the underlying JS EventEmitter with factory-generated arguments.

			The `argsFactory` parameter will be called on the JS
			thread with a valid context, allowing us to use it to
			generate the arguments to `emit`.
		*/
		protected void EmitFactory(Func<Context, object[]> argsFactory)
		{
			Dispatch(new FactoryClosure(argsFactory).Emit);
		}

		/** Call `emit` on the underlying JS EventEmitter with factory-generated arguments.

			The `argsFactory` parameter will be called on the JS
			thread with a valid context, allowing us to use it to
			generate the arguments to `emit`.
		*/
		protected void EmitFactory<T>(Func<Context, T, object[]> argsFactory, T t)
		{
			Dispatch(new FactoryClosure1<T>(argsFactory, t).Emit);
		}

		/** Call `emit("error", reason)` on the underlying JS EventEmitter.
		*/
		protected void EmitError(string reason)
		{
			Emit("error", reason);
		}

		/** Call `emit("error", new Error(reason))` on the underlying JS EventEmitter.
		*/
		protected void EmitErrorObject(string reason)
		{
			EmitFactory(CreateEmitErrorArgs, reason);
		}

		static object[] CreateEmitErrorArgs(Context context, string reason)
		{
			return new object[] { "error", context.NewError(reason) };
		}

		class ActionClosure
		{
			readonly Action<Context, Scripting.Object> _action;
			readonly Scripting.Object _arg;

			public ActionClosure(Action<Context, Scripting.Object> action, Scripting.Object arg)
			{
				_action = action;
				_arg = arg;
			}

			public void Run(Context context)
			{
				_action(context, _arg);
			}
		}

		void Dispatch(Action<Context, Scripting.Object> action, bool alwaysQueueEventBeforeInit = false)
		{
			lock (_mutex)
			{
				if (!_initialized)
				{
					if (alwaysQueueEventBeforeInit || _queueEventsBeforeInit)
					{
						_queuedEvents.Enqueue(action);
					}
					return;
				}
			}

			_context.ThreadWorker.Invoke(new ActionClosure(action, _this).Run);
		}

		/** Connect a @NativeEvent to an event.

			The @NativeEvent will be triggered whenever the event is triggered.
		*/
		protected void On(object eventName, NativeEvent nativeEvent)
		{
			On(eventName, (Scripting.Callback)nativeEvent.RaiseSync);
		}

		/** Connect a @Callback to an event.

			The @Callback will be called whenever the event is triggered.
		*/
		protected void On(object eventName, Scripting.Callback listener)
		{
			lock (_mutex)
				_listeningCallbacks.Add(Tuple.Create(eventName, listener));
			Dispatch(new OnClosure(eventName, listener).On, true);
		}

		class EmitClosure
		{
			readonly object[] _args;

			public EmitClosure(object[] args)
			{
				_args = args;
			}

			public void Emit(Context c, Scripting.Object o)
			{
				o.CallMethod(c, "emit", _args);
			}
		}

		class FactoryClosure
		{
			readonly Func<Context, object[]> _argsFactory;

			public FactoryClosure(Func<Context, object[]> argsFactory)
			{
				_argsFactory = argsFactory;
			}

			public void Emit(Context c, Scripting.Object o)
			{
				o.CallMethod(c, "emit", _argsFactory(c));
			}
		}

		class FactoryClosure1<T>
		{
			readonly Func<Context, T, object[]> _argsFactory;
			readonly T _t;

			public FactoryClosure1(Func<Context, T, object[]> argsFactory, T t)
			{
				_argsFactory = argsFactory;
				_t = t;
			}

			public void Emit(Context c, Scripting.Object o)
			{
				o.CallMethod(c, "emit", _argsFactory(c, _t));
			}
		}

		class OnClosure
		{
			readonly object _eventName;
			readonly Scripting.Callback _listener;

			public OnClosure(object eventName, Scripting.Callback listener)
			{
				_eventName = eventName;
				_listener = listener;
			}

			public void On(Context c, Scripting.Object o)
			{
				o.CallMethod(c, "on", _eventName, _listener);
			}
		}
	}
}
