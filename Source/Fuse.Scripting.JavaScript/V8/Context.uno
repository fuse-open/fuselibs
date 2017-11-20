using Uno;
using Uno.UX;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Uno.Runtime.InteropServices;
using Uno.Threading;

namespace Fuse.Scripting.V8
{
	[Require("Header.Include", "include/V8Simple.h")]
	[Require("Source.Declaration", "#undef GetMessage")]
	public extern(USE_V8) class Context: Fuse.Scripting.JavaScript.JSContext
	{
		internal Simple.JSContext _context;
		extern(DEBUG_V8) Debugger _debugger;
		internal Action<Simple.JSScriptException> _errorHandler;

		internal Function _instanceOf;
		int _vmDepth;
		internal Exception _cachedException;
		internal bool IsDisposed { get; private set; }

		extern(!CPlusPlus) Simple.JSCallbackFinalizer _handleCallbackFree;
		extern(!CPlusPlus) Simple.JSExternalFinalizer _handleExternalFree;

		public Context(): base()
		{
			_errorHandler = OnScriptException;

			if defined(CPlusPlus)
				_context = Simple.Context.Create();
			else
			{
				// V8Simple marshals the arguments below to PInvoke function pointers without
				// pinning the objects to prevent them from being GCed, so we'll have to do it
				// here instead.
				_handleCallbackFree = Handle.Free;
				_handleExternalFree = Handle.Free;
				_context = Simple.Context.Create(_handleCallbackFree, _handleExternalFree);
			}

			if defined(DEBUG_V8)
				_debugger = new Debugger(this, 5858);

			_instanceOf = Evaluate("(instanceof)", "(function(x, y) { return x instanceof y; })") as Function;
		}

		// We can't throw Uno exceptions across the V8 library boundary
		// on Android, so we use this to keep track of how deep into
		// the VM we are (e.g. because of Uno->JS->Uno->JS callbacks
		// etc) and rethrow Uno exceptions on the way out when we've
		// fully exited V8.
		internal struct EnterVM : IDisposable
		{
			Context _context;
			public EnterVM(Context context)
			{
				_context = context;
				++_context._vmDepth;
			}

			public void Dispose()
			{
				--_context._vmDepth;
				_context = null;
			}
		}

		internal void ThrowPendingExceptions()
		{
			if (_vmDepth == 0)
			{
				if (_cachedException != null)
				{
					var e = _cachedException;
					_cachedException = null;

					if (e is ScriptException)
						throw e;
					else
						throw new Exception("Unexpected Uno.Exception", e);
				}
			}
		}

		void OnScriptException(Simple.JSScriptException e)
		{
			var jsException = e.GetException();

			string exceptionName = null;

			var jsExceptionObj = Marshaller.Wrap(this, jsException) as Object;
			if (jsExceptionObj != null)
			{
				exceptionName = jsExceptionObj.CallMethod(this, "toString") as string;
			}

			var se = new ScriptException(
				exceptionName == null ? "" : exceptionName,
				e.GetMessage(_context),
				e.GetFileName(_context),
				e.GetLineNumber(),
				e.GetStackTrace(_context));
			if (_vmDepth == 0)
				throw se;
			// Ignore subsequent exceptions if we've already cached an exception.
			else if (_cachedException == null)
				_cachedException = se;
		}

		public override object Evaluate(string fileName, string code)
		{
			if (fileName == null) throw new ArgumentNullException(nameof(fileName));
			if (code == null) throw new ArgumentNullException(nameof(code));
			object result = null;
			using (var pool = new AutoReleasePool(_context))
			using (var vm = new EnterVM(this))
			{
				result = Marshaller.Wrap(this, _context.Evaluate(fileName, code, pool, _errorHandler));
			}
			ThrowPendingExceptions();
			return result;
		}

		public override Scripting.Object GlobalObject
		{
			get
			{
				using (var pool = new AutoReleasePool(_context))
					return new Object(this, _context.GetGlobalObject(pool));
			}
		}

		public override void Dispose()
		{
			_errorHandler = null;
			if defined(DEBUG_V8)
			{
				_debugger.Dispose();
				_debugger = null;
			}
			IsDisposed = true;
			_context.Release();
			_context = default(Simple.JSContext);
		}
	}

	extern(USE_V8) static class Marshaller
	{
		const string UnoHandleKey = "__unoHandle";

		internal static object Wrap(Context context, Simple.JSValue val)
		{
			var cxt = context._context;
			switch (val.GetJSType())
			{
				case Simple.JSType.Null: return null;
				case Simple.JSType.Int: return val.AsInt();
				case Simple.JSType.Double: return val.AsDouble();
				case Simple.JSType.String: return val.AsString().ToStr(cxt);
				case Simple.JSType.Bool: return val.AsBool();
				case Simple.JSType.Object:
					var res = new Object(context, val.AsObject());
					var buf = TryGetArrayBufferData(context, res);
					if (buf != null) return buf;
					return res;
				case Simple.JSType.Array: return new Array(context, val.AsArray());
				case Simple.JSType.Function: return new Function(context, val.AsFunction());
				case Simple.JSType.External: return new External(Handle.Target(val.AsExternal().GetValue(cxt)));
				default: throw new Exception("V8 marshaller: The impossible happened.");
			}
		}

		internal static Simple.JSValue Unwrap(Context context, object obj, AutoReleasePool pool)
		{
			var cxt = context._context;
			if (obj == null) return V8SimpleExtensions.Null();
			if (obj is int) return V8SimpleExtensions.NewInt((int)obj, pool);
			if (obj is double) return V8SimpleExtensions.NewDouble((double)obj, pool);
			if (obj is float) return V8SimpleExtensions.NewDouble((float)obj, pool);
			if (obj is string) return V8SimpleExtensions.NewString(cxt, (string)obj, pool).AsValue();
			if (obj is Selector) return V8SimpleExtensions.NewString(cxt, (Selector)obj, pool).AsValue();
			if (obj is bool) return V8SimpleExtensions.NewBool((bool)obj, pool);
			if (obj is byte[]) return NewArrayBuffer(context, (byte[])obj, pool);
			if (obj is Object) return ((Object)obj).GetJSObject(pool).AsValue();
			if (obj is Array) return ((Array)obj).GetJSArray(pool).AsValue();
			if (obj is Function) return ((Function)obj).GetJSFunction(pool).AsValue();
			if (obj is Callback) return V8SimpleExtensions.NewCallback(cxt, new CallbackWrapper(context, (Callback)obj).Call, pool, context._errorHandler).AsValue();
			if (obj is External) return V8SimpleExtensions.NewExternal(cxt, Handle.Create(((External)obj).Object), pool).AsValue();
			throw new Exception("Unhandled type in V8 marshaller: " + obj.GetType() + ":" + obj);
		}

		internal static /* nullable */ byte[] TryGetArrayBufferData(Context context, Object o)
		{
			var cxt = context._context;
			var ptr = o._object.TryGetArrayBufferData(context._context);
			if (ptr == IntPtr.Zero) return null;

			if (o.ContainsKey(UnoHandleKey))
			{
				var ext = o[UnoHandleKey] as External;
				var handle = ext == null
					? null
					: ext.Object as ArrayHandle;
				if (handle != null)
				{
					return handle.Array;
				}
			}
			if (o.ContainsKey("byteLength"))
			{
				var len = ToInt(o["byteLength"]);
				return ArrayHandle.CopyToArray(ptr, len);
			}
			throw new Exception("V8: Unable to get data from ArrayBuffer");
		}

		static int ToInt(object o)
		{
			if (o is int) return (int)o;
			if (o is double) return (int)(double)o;
			return 0;
		}

		class CallbackWrapper
		{
			Context _context;
			Fuse.Scripting.Callback _callback;

			public CallbackWrapper(Context context, Fuse.Scripting.Callback callback)
			{
				_context = context;
				_callback = callback;
			}

			public Simple.JSValue Call(Simple.JSValue[] args, out Simple.JSValue error)
			{
				var cxt = _context._context;
				error = default(Simple.JSValue);
				using (var pool = new AutoReleasePool(cxt))
				{
					try
					{
						return Unwrap(_context, _callback(_context, WrapArray(_context, args)), pool).Retain(cxt);
					}
					catch (Exception e)
					{
						var se = e as Scripting.Error;
						if (se != null)
						{
							var jsException = Unwrap(
								_context,
								se.Message,
								pool);
							error = jsException.Retain(cxt);
						}
						else
						{
							// Ignore subsequent exceptions if we've already cached an exception.
							if (_context._cachedException == null)
								_context._cachedException = e;
						}
						return default(Simple.JSValue);
					}
				}
				return default(Simple.JSValue); // To please Uno
			}
		}

		static Simple.JSValue NewArrayBuffer(Context context, byte[] data, AutoReleasePool pool)
		{
			var handle = new ArrayHandle(data);
			var obj = new Object(
				context,
				V8SimpleExtensions.NewExternalArrayBuffer(
					context._context,
					handle.GetIntPtr(),
					data.Length,
					pool));
			obj[UnoHandleKey] = new External(handle);
			return obj.GetJSObject(pool).AsValue();
		}

		internal static Simple.JSValue[] UnwrapArray(Context context, object[] values, AutoReleasePool pool)
		{
			var len = values.Length;
			var unwrappedValues = new Simple.JSValue[len];
			for (int i = 0; i < len; ++i)
				unwrappedValues[i] = Unwrap(context, values[i], pool);
			return unwrappedValues;
		}

		static object[] WrapArray(Context context, Simple.JSValue[] values)
		{
			int len = values == null ? 0 : values.Length;
			object[] wrappedValues = new object[len];
			for (int i = 0; i < len; ++i)
				wrappedValues[i] = Wrap(context, values[i]);
			return wrappedValues;
		}
	}
}
