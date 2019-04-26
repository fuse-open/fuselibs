using Uno.Compiler.ExportTargetInterop;
using Uno.Threading;
using Uno.UX;
using Uno;

namespace Fuse.Scripting.JavaScriptCore
{
	[extern(Android) Require("Gradle.Dependency.NativeImplementation", "org.webkit:android-jsc:r174650")]
	[extern(Android) Require("LinkLibrary", "jsc")]
	[extern(Android) Require("IncludeDirectory", "@(PACKAGE_DIR:Path)/3rdparty/JavaScriptCore/Headers")]
	[extern(iOS) Require("Xcode.Framework", "JavaScriptCore")]
	[extern(LINUX) Require("LinkLibrary", "javascriptcoregtk-4.0")]
	[extern(LINUX) Require("IncludeDirectory", "/usr/include/webkitgtk-4.0")]
	[Require("Header.Include", "JavaScriptCore/JavaScript.h")]
	public extern(USE_JAVASCRIPTCORE) class Context : Fuse.Scripting.JavaScript.JSContext
	{
		internal bool _disposed;
		internal readonly JSContextRef _context;
		internal Action<JSValueRef> _onError;
		readonly Scripting.Object _global;
		readonly JSObjectRef _functionType;
		readonly JSObjectRef _arrayType;
		readonly JSObjectRef _arrayBufferType;
		readonly JSObjectRef _byteArrayType;
		readonly JSClassRef _unoFinalizerClass;
		readonly JSClassRef _unoCallbackClass;

		int _vmDepth;
		internal Exception _pendingException;

		public Context(): base()
		{
			_context = JSContextRef.Create();

			// To not have to reconstruct the delegate all the
			// time.  Note: Creates a cyclic reference to `this`,
			// which can be broken with `Dispose`.
			_onError = OnError;

			var global = _context.GlobalObject;
			_global = new Object(this, global);

			Action<JSValueRef> onSetupError = OnSetupError;

			_functionType = global.GetProperty(_context, "Function", onSetupError).GetJSObjectRef(_context);
			_functionType.GetJSValueRef().Protect(_context);
			_arrayType = global.GetProperty(_context, "Array", onSetupError).GetJSObjectRef(_context);
			_arrayType.GetJSValueRef().Protect(_context);
			_arrayBufferType = global.GetProperty(_context, "ArrayBuffer", onSetupError).GetJSObjectRef(_context);
			_arrayBufferType.GetJSValueRef().Protect(_context);
			_byteArrayType = global.GetProperty(_context, "Uint8Array", onSetupError).GetJSObjectRef(_context);
			_byteArrayType.GetJSValueRef().Protect(_context);

			_unoFinalizerClass = JSClassRef.CreateUnoFinalizer();
			_unoCallbackClass = JSClassRef.CreateUnoCallback();
		}

		public override void Dispose()
		{
			if (!_disposed)
			{
				_disposed = true;
				_onError = null;

				_functionType.GetJSValueRef().DeferedUnprotect();
				_arrayType.GetJSValueRef().DeferedUnprotect();
				_arrayBufferType.GetJSValueRef().DeferedUnprotect();
				_byteArrayType.GetJSValueRef().DeferedUnprotect();

				_unoFinalizerClass.Dispose();
				_unoCallbackClass.Dispose();

				_context.Dispose();
			}
		}

		~Context()
		{
			Dispose();
		}

		// We can't throw Uno exceptions across the JSC library boundary,
		// so we use this to keep track of how deep into the VM we are
		// (e.g. because of Uno->JS->Uno->JS callbacks etc) and rethrow
		// Uno exceptions on the way out when we've fully exited the VM.

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

		internal void ThrowPendingException()
		{
			if (_vmDepth > 0)
				return;

			if (_pendingException != null)
			{
				var e = _pendingException;
				_pendingException = null;
				throw new Exception("Unexpected Uno.Exception", e);
			}
		}

		public override object Evaluate(string fileName, string code)
		{
			if (fileName == null) throw new ArgumentException("Context.Evaluate.fileName");
			if (code == null) throw new ArgumentException("Context.Evaluate.code");

			object ret = null;
			using (var vm = new EnterVM(this))
			{
				ret = Wrap(_context.EvaluateScript(
					code,
					default(JSObjectRef),
					fileName,
					0,
					_onError));
			}

			ThrowPendingException();
			return ret;
		}

		public override Scripting.Object GlobalObject
		{
			get
			{
				return _global;
			}
		}

		static void OnSetupErrorError(JSValueRef exception)
		{
			//  (╯°□°）╯︵ ┻━┻
		}

		void OnSetupError(JSValueRef exception)
		{
			var str = exception.ToString(_context, OnSetupErrorError);
			str = str == null ? "Unknown" : str;
			throw new Exception("Fatal exception during Fuse.Scripting.JavaScriptCore startup: " + str);
		}

		void OnError(JSValueRef exception)
		{
			string name = null;
			string message = null;
			string file = null;
			int lineNumber = -1;
			string stack = null;

			var wrapped = Wrap(exception);
			if (wrapped is Object)
			{
				Object o = (Object) wrapped;

				name = o["name"] as string ?? name;
				message = o["message"] as string ?? message;
				file = o["fileName"] as string
					?? o["sourceURL"] as string ?? file;
				var l1 = o["line"];
				var l2 = o["lineNumber"];
				lineNumber =
					l1 is double ? (int)(double)l1 :
					(l2 is double ? (int)(double)l2 :
					(l1 is int ? (int)l1 :
					(l2 is int ? (int)l2 : lineNumber)));
				stack = o["stack"] as string ?? stack;
			}
			else
			{
				message = wrapped != null ? wrapped.ToString() : message;
			}
			throw new ScriptException(name, message, file, lineNumber, stack);
		}

		internal object Wrap(JSValueRef value)
		{
			switch (value.GetType(_context))
			{
				case JSType.Undefined: return null;
				case JSType.Null: return null;
				case JSType.Boolean: return value.ToBoolean(_context);
				case JSType.Number: return value.ToNumber(_context, _onError);
				case JSType.String: return value.ToString(_context, _onError);
				case JSType.Object:
				{
					var obj = value.GetJSObjectRef(_context);
					var priv = obj.GetPrivate();
					if (priv != null && priv is External)
						return priv;
					if (value.IsInstanceOfConstructor(_context, _functionType, _onError)) return new Function(this, obj);
					if (value.IsInstanceOfConstructor(_context, _arrayType, _onError)) return new Array(this, obj);
					if (value.IsInstanceOfConstructor(_context, _arrayBufferType, _onError)) return WrapArrayBuffer(obj);
					return new Object(this, obj);
				}
				case JSType.FlipTheTable: throw new Exception("Internal error in JavaScriptCore wrapper");
				default: throw new Exception("Unhandled JSType in JavaScriptCore wrapper");
			}
		}

		internal object[] Wrap(JSValueRef[] values)
		{
			object[] result = new object[values.Length];
			for (int i = 0; i < values.Length; ++i)
			{
				result[i] = Wrap(values[i]);
			}
			return result;
		}

		internal JSValueRef Unwrap(object obj)
		{
			if (obj == null) return JSValueRef.MakeNull(_context);
			if (obj is int) return JSValueRef.MakeNumber(_context, (double)(int)obj);
			if (obj is double) return JSValueRef.MakeNumber(_context, (double)obj);
			if (obj is float) return JSValueRef.MakeNumber(_context, (double)(float)obj);
			if (obj is string) return JSValueRef.MakeString(_context, (string)obj);
			if (obj is Selector) return JSValueRef.MakeString(_context, (string)(Selector)obj);
			if (obj is bool) return JSValueRef.MakeBoolean(_context, (bool)obj);
			if (obj is byte[]) return UnwrapArrayBuffer((byte[])obj);
			if (obj is Object) return ((Object)obj)._value.GetJSValueRef();
			if (obj is Array) return ((Array)obj)._value.GetJSValueRef();
			if (obj is Function) return ((Function)obj)._value.GetJSValueRef();
			if (obj is External) return JSObjectRef.Make(_context, _unoFinalizerClass, obj).GetJSValueRef();
			if (obj is Callback)
			{
				var result = JSObjectRef.Make(
					_context,
					_unoCallbackClass,
					new JSClassRef.RawCallback(new CallbackWrapper(this, (Callback)obj).Call));
				result.SetPrototype(_context, _functionType.GetJSValueRef());
				return result.GetJSValueRef();
			}
			throw new Exception("Unhandled type in JavaScriptCore wrapper: " + obj);
		}

		internal JSValueRef[] Unwrap(object[] obj)
		{
			var result = new JSValueRef[obj.Length];
			for (int i = 0; i < obj.Length; ++i)
			{
				result[i] = Unwrap(obj[i]);
			}
			return result;
		}

		const string UnoHandleKey = "__unoHandle";

		JSValueRef UnwrapArrayBuffer(byte[] data)
		{
			var arrayBuffer = JSTypedArray.TryMakeArrayBufferWithBytes(_context, data, _onError);
			if (arrayBuffer != default(JSObjectRef))
			{
				arrayBuffer.SetProperty(_context, UnoHandleKey, Unwrap(new External(data)), _onError);
			}
			else
			{
				// TODO Maybe we could use `JSObjectMakeArray` to optimise this?
				var len = data.Length;
				arrayBuffer = _arrayBufferType.CallAsConstructor(
					_context,
					new JSValueRef[] { JSValueRef.MakeNumber(_context, (double)len) },
					_onError);
				var byteArray = _byteArrayType.CallAsConstructor(
					_context,
					new JSValueRef[] { arrayBuffer.GetJSValueRef() },
					_onError);
				for (int i = 0; i < len; ++i)
				{
					byteArray.SetPropertyAtIndex(
						_context,
						i,
						JSValueRef.MakeNumber(_context, (double)data[i]),
						_onError);
				}
			}
			return arrayBuffer.GetJSValueRef();
		}

		byte[] WrapArrayBuffer(JSObjectRef value)
		{
			// >= iOS 10 path
			if (value.HasProperty(_context, UnoHandleKey))
			{
				// It's a wrapped Uno array.
				var unoHandle = Wrap(value.GetProperty(_context, UnoHandleKey, _onError)) as External;
				if (unoHandle != null)
				{
					var result = unoHandle.Object as byte[];
					if (result != null)
						return result;
				}
			}

			var res = JSTypedArray.TryCopyArrayBufferBytes(_context, value, _onError);
			if (res != null)
				return res;

			// Slow path
			var byteArray = _byteArrayType.CallAsConstructor(
				_context,
				new JSValueRef[] { value.GetJSValueRef() },
				_onError);
			var len = (int)value.GetProperty(
				_context,
				"byteLength",
				_onError).ToNumber(
					_context,
					_onError);
			res = new byte[len];
			for (int i = 0; i < len; ++i)
			{
				res[i] = (byte)byteArray.GetPropertyAtIndex(
					_context,
					i,
					_onError).ToNumber(
						_context,
						_onError);
			}
			return res;
		}

		extern(USE_JAVASCRIPTCORE) class CallbackWrapper
		{
			readonly Context _context;
			readonly Callback _callback;

			public CallbackWrapper(Context context, Callback callback)
			{
				_context = context;
				_callback = callback;
			}

			public JSValueRef Call(JSValueRef[] args, out JSValueRef exception)
			{
				exception = default(JSValueRef);
				try
				{
					return _context.Unwrap(_callback(_context, _context.Wrap(args)));
				}
				catch (Exception e)
				{
					var se = e as Scripting.Error;
					if (se != null)
						exception = JSValueRef.MakeString(_context._context, e.Message);
					else
					{
						if (_context._pendingException == null)
							_context._pendingException = e;
					}
				}
				return default(JSValueRef);
			}
		}
	}
}
