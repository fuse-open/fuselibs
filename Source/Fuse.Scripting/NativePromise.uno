using Uno;
using Uno.Threading;

namespace Fuse.Scripting
{
	public delegate T ResultFactory<T>(object[] args);
	public delegate Future<T> FutureFactory<T>(object[] args);
	public delegate TJSResult ResultConverter<T, TJSResult>(Context context, T result);

	class FactoryClosure<T>
	{
		ResultFactory<T> _factory;
		object[] _args;
		Promise<T> _promise;

		public FactoryClosure(ResultFactory<T> factory, object[] args, Promise<T> promise)
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
				res = _factory(_args);
			}
			catch (Exception e)
			{
				_promise.Reject(e);
				return;
			}

			_promise.Resolve(res);
		}
	}

	public sealed class NativePromise<T, TJSResult>: NativeMember
	{
		FutureFactory<T> _futureFactory;
		ResultConverter<T, TJSResult> _resultConverter;
		ResultFactory<T> _func;

		public NativePromise(string name, ResultFactory<T> func, ResultConverter<T, TJSResult> resultConverter = null): base(name)
		{
			_func = func;
			_futureFactory = (FutureFactory<T>)Factory;
			_resultConverter = resultConverter;
		}

		Future<T> Factory(object[] args)
		{
			var future = new Promise<T>();
			new Thread(new FactoryClosure<T>(_func, args, future).Run).Start();
			return future;
		}

		public NativePromise(string name, FutureFactory<T> futureFactory, ResultConverter<T, TJSResult> resultConverter = null): base(name)
		{
			_futureFactory = futureFactory;
			_resultConverter = resultConverter;
		}

		protected override object CreateObject()
		{ 
			return (Callback)new ContextClosure(Context, _futureFactory, _resultConverter).CreatePromise;
		}

		class ContextClosure
		{
			Context _c;
			FutureFactory<T> _factory;
			ResultConverter<T, TJSResult> _converter;
			public ContextClosure(Context c, FutureFactory<T> factory, ResultConverter<T, TJSResult> converter)
			{
				_c = c;
				_factory = factory;
				_converter = converter;
			}
			internal object CreatePromise(Context context, object[] args)
			{
				var promise = (Function)_c.GlobalObject["Promise"]; // HACK - TODO: get rid of this
				var future = _factory(args);
				return promise.Construct((Callback)new PromiseClosure(_c, future, _converter).Run);
			}
		}
			
	    class PromiseClosure
	    {
			Context _c;
	    	Future<T> _promise;
	    	Function _resolve = null;
	    	Function _reject = null;
	    	ResultConverter<T, TJSResult> _converter;
			T _result = default(T);
			Exception _reason;

	    	public PromiseClosure(Context context, Future<T> promise, ResultConverter<T, TJSResult> converter)
	    	{
				_c = context;
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
	    			_c.Dispatcher.Invoke(this.InternalResolve);
	    	}

	    	void InternalResolve()
    		{
    			if(_converter != null)
    				_resolve.Call(_converter(_c, _result));
    			else
    				_resolve.Call(_result);
    		}

	    	void Reject(Exception reason)
	    	{
	    		_reason = reason;
	    		if(_reject != null)
	    			_c.Dispatcher.Invoke(this.InternalReject);
	    	}

	    	void InternalReject()
	    	{
	    		_reject.Call(_reason.Message);
	    	}
	    }
	}
}
