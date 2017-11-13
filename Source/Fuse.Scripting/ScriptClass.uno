using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.Collections;

namespace Fuse.Scripting
{
	public enum ExecutionThread
	{
		JavaScript,
		MainThread,
		Any = JavaScript
	}

	public abstract class ScriptMember
	{
		public readonly string Name;

		protected ScriptMember(string name)
		{
			if (name == null)
				throw new ArgumentNullException(nameof(name));

			if (name.Length == 0)
				throw new ArgumentOutOfRangeException(nameof(name));

			Name = name;
		}
	}

	public class ScriptReadonlyProperty: ScriptMember
	{
		public readonly object Value;

		public ScriptReadonlyProperty(string name, object value): base(name)
		{
			Value = value;
		}
	}

	public abstract class ScriptProperty: ScriptMember
	{
		public readonly string Modifier;
		protected ScriptProperty(string name, string modifier = null): base(name) 
		{
			Modifier = modifier ?? "";
		}
		public abstract Property GetProperty(PropertyObject owner);
	}

	public sealed class ScriptProperty<TOwner, TValue>: ScriptProperty
	{
		readonly Func<TOwner, Property<TValue>> _getter;
		public override Property GetProperty(PropertyObject owner) 
		{ 
			if (!(owner is TOwner)) throw new Exception("ScriptProperty: incorrect owner type");
			return _getter((TOwner)owner); 
		}
		public ScriptProperty(string name, Func<TOwner, Property<TValue>> getter, string modifier = null): base(name, modifier) 
		{
			_getter = getter;
		}
	}

	public abstract class ScriptMethod: ScriptMember
	{
		protected ScriptMethod(string name): base(name)
		{
		}

		public abstract object Call(Context c, object obj, object[] args);
	}

	public class ScriptMethodInline: ScriptMethod
	{
		public readonly string Code;

		[Obsolete("Use ScriptMethodInline(string, string) instead")]
		public ScriptMethodInline(string name, ExecutionThread thread, string code): base(name)
		{
			Code = code;
		}

		public ScriptMethodInline(string name, string code): base(name)
		{
			Code = code;
		}

		public override object Call(Context c, object obj, object[] args)
		{
			throw new Exception(); // Not applicable
		}
	}

	public class ScriptMethod<T>: ScriptMethod
	{
		// legacy
		[Obsolete]
		public readonly ExecutionThread Thread;

		readonly Func<Context, T, object[], object> _method;
		readonly Action<T> _voidMethod;

		[Obsolete("Use ScriptMethod<T>(string, Uno.Func<Fuse.Scripting.Context, T, object[], object)>) instead")]
		public ScriptMethod(string name, Func<Context, T, object[], object> method, ExecutionThread thread): this(name, method)
		{
			if (thread == ExecutionThread.MainThread)
				throw new ArgumentException("Cannot call a non-void method asynchronously", nameof(thread));

			Thread = thread;
		}

		/** Create a ScriptMethod that will run on the script-thread

			@param name Name of method
			@param method The native implementation of the method
		*/
		public ScriptMethod(string name, Func<Context, T, object[], object> method): base(name)
		{
			if (method == null)
				throw new ArgumentNullException(nameof(method));

			_method = method;
		}

		[Obsolete("Use ScriptMethod<T>(string, Uno.Action<T)>), ScriptMethod<T>(string, Uno.Action<T, object[])>) or ScriptMethod<T>(string, Uno.Func<Fuse.Scripting.Context, T, object[], object)>) instead")]
		public ScriptMethod(string name, Action<Context, T, object[]> method, ExecutionThread thread): base(name)
		{
			Thread = thread;

			if (method == null)
				throw new ArgumentNullException(nameof(method));

			_method = new LegacyMethodClosure<T>(method, thread).Run;
		}

		class LegacyMethodClosure<T>
		{
			readonly Action<Context, T, object[]> _action;
			readonly ExecutionThread _thread;
			public LegacyMethodClosure(Action<Context, T, object[]> action, ExecutionThread thread)
			{
				_action = action;
				_thread = thread;
			}

			public object Run(Context c, T obj, object[] args)
			{
				if (_thread == ExecutionThread.MainThread)
					UpdateManager.PostAction(new CallWithArgumentsClosure(_action, c, obj, args).Run);
				else
					_action(c, (T)obj, args);
				return null;
			}

			class CallWithArgumentsClosure
			{
				readonly Action<Context, T, object[]> _action;
				readonly Context _context;
				readonly T _obj;
				readonly object[] _args;
				public CallWithArgumentsClosure(Action<Context, T, object[]> action, Context context, T obj, object[] args)
				{
					_action = action;
					_context = context;
					_obj = obj;
					_args = args;
				}

				public void Run()
				{
					_action(_context, _obj, _args);
				}
			}
		}

		/** Create an argument-less ScriptMethod that will run on the UI-thread

			@param name Name of method
			@param method The native implementation of the method
		*/
		public ScriptMethod(string name, Action<T> method): base(name)
		{
			if (method == null)
				throw new ArgumentNullException(nameof(method));

			_voidMethod = method;
		}

		/** Create a ScriptMethod that will run on the UI-thread

			@param name Name of method
			@param method The native implementation of the method
		*/
		public ScriptMethod(string name, Action<T, object[]> method): base(name)
		{
			if (method == null)
				throw new ArgumentNullException(nameof(method));

			_method = new ArgumentMirrorClosure<T>(method).Run;
		}

		class ArgumentMirrorClosure<T>
		{
			readonly Action<T, object[]> _action;
			public ArgumentMirrorClosure(Action<T, object[]> action)
			{
				_action = action;
			}

			public object Run(Context c, T obj, object[] args)
			{
				var marshalledArguments = new List<object>();
				foreach (var arg in args)
					marshalledArguments.Add(c.Reflect(arg));

				UpdateManager.PostAction(new CallWithArgumentsClosure(_action, obj, marshalledArguments.ToArray()).Run);
				return null;
			}

			class CallWithArgumentsClosure
			{
				readonly Action<T, object[]> _action;
				readonly T _obj;
				readonly object[] _args;
				public CallWithArgumentsClosure(Action<T, object[]> action, T obj, object[] args)
				{
					_action = action;
					_obj = obj;
					_args = args;
				}

				public void Run()
				{
					_action(_obj, _args);
				}
			}
		}

		public override object Call(Context c, object obj, object[] args)
		{

			if (_voidMethod != null)
			{
				if (args.Length != 0)
				{
					var name = obj.GetType().FullName + "." + Name;
					Fuse.Diagnostics.UserError(string.Format("{0} takes no arguments, but {1} was provided", name, args.Length), obj);
					return null;
				}

				UpdateManager.PostAction(new CallClosure(_voidMethod, (T)obj).Run);
				return null;
			}
			else
			{
				return _method(c, (T)obj, args);
			}
		}
		
		class CallClosure
		{
			readonly Action<T> _method;
			readonly T _obj;
			readonly object[] _args;

			public CallClosure(Action<T> method, T obj)
			{
				_method = method;
				_obj = obj;
			}

			readonly Context _context;
			readonly Action<Context, T, object[]> _oldMethod;
			public CallClosure(Context context, Action<Context, T, object[]> method, T obj, object[] args)
			{
				_context = context;
				_oldMethod = method;
				_obj = obj;
				_args = args;
			}

			public void Run()
			{
				if (_method != null)
					_method(_obj);
				else
					_oldMethod(_context, _obj, _args);
			}
		}

	}

	public class ScriptPromise<TSelf,TResult,TJSResult> : ScriptMethod
	{
		public delegate Future<TResult> FutureFactory<TSelf,TResult>(Context context, TSelf self, object[] args);
		public delegate TJSResult ResultConverter<TResult,TJSResult>(Context context, TResult result);

		public readonly ExecutionThread Thread;
		FutureFactory<TSelf,TResult> _futureFactory;
		ResultConverter<TResult,TJSResult> _resultConverter;

		public ScriptPromise(
			string name,
			ExecutionThread thread,
			FutureFactory<TSelf,TResult> futureFactory,
			ResultConverter<TResult,TJSResult> resultConverter = null) : base(name)
		{
			Thread = thread;
			_futureFactory = futureFactory;
			_resultConverter = resultConverter;
		}

		Future<TResult> InvokeFutureFactory(Context context, TSelf self, object[] args)
		{
			if (_futureFactory == null)
			{
				var p = new Promise<TResult>();
				p.Reject(new Exception("FutureFactory is null"));
				return p;
			}

			var future = _futureFactory(context, self, args);
			if (future == null)
			{
				var p = new Promise<TResult>();
				p.Reject(new Exception("FutureFactory returned null"));
				return p;
			}
			return future;
		}

		public override object Call(Context c, object obj, object[] args)
		{
			var promise = (Function)c.GlobalObject["Promise"];
			var promiseClosure = new PromiseClosure(c, _resultConverter);
			var self = (TSelf)obj;

			if (Thread == ExecutionThread.MainThread)
				UpdateManager.PostAction(new FutureClosure(c, InvokeFutureFactory, promiseClosure, self, args).Run);
			else
				promiseClosure.OnFutureReady(InvokeFutureFactory(c, self, args));

			return promise.Construct(c, (Callback)promiseClosure.Run);
		}

		class FutureClosure
		{
			Context _context;
			FutureFactory<TSelf,TResult> _futureFactory;
			PromiseClosure _promiseClosure;
			TSelf _self;
			object[] _args;

			public FutureClosure(
				Context context,
				FutureFactory<TSelf,TResult> futureFactory,
				PromiseClosure promiseClosure,
				TSelf self,
				object[] args)
			{
				_context = context;
				_futureFactory = futureFactory;
				_promiseClosure = promiseClosure;
				_self = self;
				_args = args;
			}

			Future<TResult> _future;
			public void Run()
			{
				_future = _futureFactory(_context, _self, _args);
				_context.Invoke(DispatchFuture);
			}

			void DispatchFuture(Scripting.Context action)
			{
				_promiseClosure.OnFutureReady(_future);
			}
		}

		class PromiseClosure
		{
			Context _context;
			ResultConverter<TResult,TJSResult> _resultConverter;

			public PromiseClosure(Context context, ResultConverter<TResult,TJSResult> resultConverter)
			{
				_context = context;
				_resultConverter = resultConverter;
			}

			Function _resolve;
			Function _reject;
			public object Run(Context context, object[] args)
			{
				if (args.Length > 0)
					_resolve = args[0] as Function;

				if (args.Length > 1)
					_reject = args[1] as Function;

				if (_future != null)
					_future.Then(Resolve, Reject);

				return null;
			}

			Future<TResult> _future;
			public void OnFutureReady(Future<TResult> future)
			{
				_future = future;
				if (_resolve != null || _reject != null)
					_future.Then(Resolve, Reject);
			}

			TResult _result = default(TResult);
			void Resolve(TResult result)
			{
				_result = result;
				if (_resolve != null)
					_context.ThreadWorker.Invoke(DispatchResolve);
			}

			Exception _reason;
			void Reject(Exception reason)
			{
				_reason = reason;
				if (_reject != null)
					_context.ThreadWorker.Invoke(DispatchReject);
			}

			void DispatchResolve(Scripting.Context context)
			{
				if (_resultConverter != null)
					_resolve.Call(_context, _resultConverter(_context, _result));
				else
					_resolve.Call(_context, _result);
			}

			void DispatchReject(Scripting.Context context)
			{
				_reject.Call(_context, _reason.Message);
			}
		}
	}

	public class ScriptClass
	{
		readonly Type _unoType;
		public Type Type { get { return _unoType; } }
		public ScriptClass SuperType
		{
			get
			{
				return Get(_unoType.BaseType);
			}
		}

		public static ScriptClass Get(Type t)
		{
			while (t != null)
			{
				ScriptClass sc;
				if (_unoTypeToScriptClass.TryGetValue(t, out sc))
					return sc;
				t = t.BaseType;
			}
			return null;
		}

		static Dictionary<Type, ScriptClass> _unoTypeToScriptClass = new Dictionary<Type, ScriptClass>();

		readonly ScriptMember[] _members;
		public ScriptMember[] Members { get { return _members; } }
		
		ScriptClass(Type unoType, ScriptMember[] members)
		{
			_unoType = unoType;
			_members = members;
		}

		public static void Register(Type unoType, params ScriptMember[] members)
		{
			_unoTypeToScriptClass.Add(unoType, new ScriptClass(unoType, members));
		}
	}
}
