using Uno;
using Uno.Threading;

namespace Fuse.Scripting
{
	[Obsolete("Please use ResultFactory2 instead.")]
	public delegate T ResultFactory<T>(object[] args);
	public delegate T ResultFactory2<T>(Context context, object[] args);
	[Obsolete("Please use FutureFactory2 instead.")]
	public delegate Future<T> FutureFactory<T>(object[] args);
	public delegate Future<T> FutureFactory2<T>(Context context, object[] args);
	public delegate TJSResult ResultConverter<T, TJSResult>(Context context, T result);

	class FactoryClosure<T>
	{
		ResultFactory2<T> _factory;
		Context _context;
		object[] _args;
		Promise<T> _promise;

		public FactoryClosure(ResultFactory2<T> factory, Context context, object[] args, Promise<T> promise)
		{
			_factory = factory;
			_args = args;
			_promise = promise;
		}

		public void Run()
		{
			T res = default(T);
			try
			{
				res = _factory(_context, _args);
			}
			catch (Exception e)
			{
				_promise.Reject(e);
				return;
			}

			_promise.Resolve(res);
		}
	}

	public sealed class NativePromise<T, TJSResult> : NativeMember
	{
		FutureFactory2<T> _futureFactory;
		ResultConverter<T, TJSResult> _resultConverter;
		ResultFactory2<T> _func;

		[Obsolete("Please add the Context parameter to your delegate.")]
		public NativePromise(string name, ResultFactory<T> func, ResultConverter<T, TJSResult> resultConverter = null): base(name)
		{
			_func = new ResultFactoryClosure<T>(func).Run;
			_futureFactory = (FutureFactory2<T>)Factory;
			_resultConverter = resultConverter;
		}

		public NativePromise(string name, ResultFactory2<T> func, ResultConverter<T, TJSResult> resultConverter = null): base(name)
		{
			_func = func;
			_futureFactory = (FutureFactory2<T>)Factory;
			_resultConverter = resultConverter;
		}

		Future<T> Factory(Context context, object[] args)
		{
			var future = new Promise<T>();
			new Thread(new FactoryClosure<T>(_func, context, args, future).Run).Start();
			return future;
		}

		[Obsolete("Please add the Context parameter to your delegate.")]
		public NativePromise(string name, FutureFactory<T> futureFactory, ResultConverter<T, TJSResult> resultConverter = null): base(name)
		{
			_futureFactory = new FutureFactoryClosure<T>(futureFactory).Run;
			_resultConverter = resultConverter;
		}

		public NativePromise(string name, FutureFactory2<T> futureFactory, ResultConverter<T, TJSResult> resultConverter = null): base(name)
		{
			_futureFactory = futureFactory;
			_resultConverter = resultConverter;
		}

		protected override object CreateObject(Context context)
		{
			return (Callback)new ContextClosure(_futureFactory, _resultConverter).CreatePromise;
		}

		class ContextClosure
		{
			FutureFactory2<T> _factory;
			ResultConverter<T, TJSResult> _converter;

			public ContextClosure(FutureFactory2<T> factory, ResultConverter<T, TJSResult> converter)
			{
				_factory = factory;
				_converter = converter;
			}

			internal object CreatePromise(Context context, object[] args)
			{
				var promise = (Function)context.GlobalObject["Promise"];
				var future = _factory(context, args);
				return promise.Construct(context, (Callback)new PromiseClosure(context.ThreadWorker, future, _converter).Run);
			}
		}

		class PromiseClosure
		{
			readonly IThreadWorker _threadWorker;
			Future<T> _promise;
			Function _resolve = null;
			Function _reject = null;
			ResultConverter<T, TJSResult> _converter;
			T _result = default(T);
			Exception _reason;

			public PromiseClosure(IThreadWorker threadWorker, Future<T> promise, ResultConverter<T, TJSResult> converter)
			{
				_threadWorker = threadWorker;
				_promise = promise;
				_converter = converter;
			}

			public object Run(Context context, object[] args)
			{
				if (args.Length > 0)
					_resolve = args[0] as Function;

				if (args.Length > 1)
					_reject = args[1] as Function;

				_promise.Then(Resolve, Reject);

				return null;
			}

			void Resolve(T result)
			{
				_result = result;
				if(_resolve != null)
					_threadWorker.Invoke(this.InternalResolve);
			}

			void InternalResolve(Context context)
			{
				if(_converter != null)
					_resolve.Call(context, _converter(context, _result));
				else
					_resolve.Call(context, _result);
			}

			void Reject(Exception reason)
			{
				_reason = reason;
				if(_reject != null)
					_threadWorker.Invoke(this.InternalReject);
			}

			void InternalReject(Context context)
			{
				_reject.Call(context, _reason.Message);
			}
		}

		class ResultFactoryClosure<T>
		{
			readonly ResultFactory<T> _func;

			public ResultFactoryClosure(ResultFactory<T> func)
			{
				_func = func;
			}

			public T Run(Context context, object[] args)
			{
				return _func(args);
			}
		}

		class FutureFactoryClosure<T>
		{
			readonly FutureFactory<T> _func;

			public FutureFactoryClosure(FutureFactory<T> func)
			{
				_func = func;
			}

			public Future<T> Run(Context context, object[] args)
			{
				return _func(args);
			}
		}
	}
}
