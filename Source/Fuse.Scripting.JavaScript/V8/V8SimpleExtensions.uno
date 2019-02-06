using Fuse.Scripting.V8.Simple;
using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Uno.Runtime.InteropServices;

// Adds error-checking and memory management to the V8Simple interface

namespace Fuse.Scripting.V8
{
	[Require("Header.Include", "include/V8Simple.h")]
	[Require("Source.Declaration", "#undef GetMessage")]
	static extern(USE_V8) class V8SimpleExtensions
	{
		// Context
		public static void Retain(this JSContext context) { Simple.Context.Retain(context); }
		public static void Release(this JSContext context) { Simple.Context.Release(context); }
		public extern(CPlusPlus) static JSContext Create()
		{
			return Simple.Context.Create();
		}
		public extern(DOTNET) static JSContext Create(JSCallbackFinalizer callbackFinalizer, JSExternalFinalizer externalFinalizer)
		{
			return Simple.Context.Create(callbackFinalizer, externalFinalizer);
		}
		public static JSValue Evaluate(this JSContext context, string fileName, string code, AutoReleasePool pool, Action<JSScriptException> errorHandler)
		{
			JSScriptException error;
			var result = Simple.Context.EvaluateCreate(
				context,
				NewString(context, fileName, pool),
				NewString(context, code, pool),
				out error);
			Error.Check(context, error, errorHandler);
			return pool.AutoRelease(result);
		}
		public static JSObject GetGlobalObject(this JSContext context, AutoReleasePool pool)
		{
			var result = Simple.Context.CopyGlobalObject(context);
			return pool.AutoRelease(result);
		}

		// Value
		public static JSType GetJSType(this JSValue value) { return Simple.Value.GetType(value); }
		public static JSValue Retain(this JSValue value, JSContext context) { Simple.Value.Retain(context, value); return value; }
		public static void Release(this JSValue value, JSContext context) { Simple.Value.Release(context, value); }
		public static JSValue Null() { return Simple.Value.JSNull(); }
		public static JSValue NewInt(int value, AutoReleasePool pool) { return pool.AutoRelease(Simple.Value.CreateInt(value)); }
		public static JSValue NewDouble(double value, AutoReleasePool pool) { return pool.AutoRelease(Simple.Value.CreateDouble(value)); }
		public static JSValue NewBool(bool value, AutoReleasePool pool) { return pool.AutoRelease(Simple.Value.CreateBool(value)); }
		public static int AsInt(this JSValue value)
		{
			JSRuntimeError error;
			var result = Simple.Value.AsInt(value, out error);
			Error.Check(error);
			return result;
		}
		public static double AsDouble(this JSValue value)
		{
			JSRuntimeError error;
			var result = Simple.Value.AsDouble(value, out error);
			Error.Check(error);
			return result;
		}
		public static JSString AsString(this JSValue value)
		{
			JSRuntimeError error;
			var result = Simple.Value.AsString(value, out error);
			Error.Check(error);
			return result;
		}
		public static bool AsBool(this JSValue value)
		{
			JSRuntimeError error;
			var result = Simple.Value.AsBool(value, out error);
			Error.Check(error);
			return result;
		}
		public static JSObject AsObject(this JSValue value)
		{
			JSRuntimeError error;
			var result = Simple.Value.AsObject(value, out error);
			Error.Check(error);
			return result;
		}
		public static JSArray AsArray(this JSValue value)
		{
			JSRuntimeError error;
			var result = Simple.Value.AsArray(value, out error);
			Error.Check(error);
			return result;
		}
		public static JSFunction AsFunction(this JSValue value)
		{
			JSRuntimeError error;
			var result = Simple.Value.AsFunction(value, out error);
			Error.Check(error);
			return result;
		}
		public static JSExternal AsExternal(this JSValue value)
		{
			JSRuntimeError error;
			var result = Simple.Value.AsExternal(value, out error);
			Error.Check(error);
			return result;
		}
		public static bool StrictEquals(this JSValue value, JSContext context, JSValue that)
		{
			return Simple.Value.StrictEquals(context, value, that);
		}

		// String
		public static JSString NewString(JSContext context, string str, AutoReleasePool pool)
		{
			JSRuntimeError error;
			var result = Simple.Value.CreateString(context, str, str.Length, out error);
			Error.Check(error);
			return pool.AutoRelease(result);
		}
		public static int Length(this JSString str, JSContext context) { return Simple.Value.Length(context, str); }
		public static string ToStr(this JSString str, JSContext context) { return Simple.Value.ToString(context, str); }
		public static JSValue AsValue(this JSString str) { return Simple.Value.AsValue(str); }

		// Object
		public static JSValue GetProperty(this JSObject obj, JSContext context, string key, AutoReleasePool pool, Action<JSScriptException> errorHandler)
		{
			JSScriptException error;
			var result = Simple.Value.CopyProperty(context, obj, NewString(context, key, pool), out error);
			Error.Check(context, error, errorHandler);
			return pool.AutoRelease(result);
		}
		public static void SetProperty(this JSObject obj, JSContext context, string key, JSValue value, AutoReleasePool pool, Action<JSScriptException> errorHandler)
		{
			JSScriptException error;
			Simple.Value.SetProperty(context, obj, NewString(context, key, pool), value, out error);
			Error.Check(context, error, errorHandler);
		}
		public static JSArray GetOwnPropertyNames(this JSObject obj, JSContext context, AutoReleasePool pool, Action<JSScriptException> errorHandler)
		{
			JSScriptException error;
			var result = Simple.Value.CopyOwnPropertyNames(context, obj, out error);
			Error.Check(context, error, errorHandler);
			return pool.AutoRelease(result);
		}
		public static bool HasProperty(this JSObject obj, JSContext context, string key, AutoReleasePool pool, Action<JSScriptException> errorHandler)
		{
			JSScriptException error;
			var result = Simple.Value.HasProperty(context, obj, NewString(context, key, pool), out error);
			Error.Check(context, error, errorHandler);
			return result;
		}
		public static JSObject NewExternalArrayBuffer(JSContext context, IntPtr data, int byteLength, AutoReleasePool pool)
		{
			return pool.AutoRelease(Simple.Value.CreateExternalArrayBuffer(context, data, byteLength));
		}
		public static IntPtr TryGetArrayBufferData(this JSObject obj, JSContext context)
		{
			JSRuntimeError error;
			var result = Simple.Value.GetArrayBufferData(context, obj, out error);
			if (error == JSRuntimeError.TypeError)
				return IntPtr.Zero;
			Error.Check(error);
			return result;
		}
		public static JSValue AsValue(this JSObject obj) { return Simple.Value.AsValue(obj); }

		// Array
		public static JSValue GetProperty(this JSArray arr, JSContext context, int index, AutoReleasePool pool, Action<JSScriptException> errorHandler)
		{
			JSScriptException error;
			var result = Simple.Value.CopyProperty(context, arr, index, out error);
			Error.Check(context, error, errorHandler);
			return pool.AutoRelease(result);
		}
		public static void SetProperty(this JSArray arr, JSContext context, int index, JSValue value, Action<JSScriptException> errorHandler)
		{
			JSScriptException error;
			Simple.Value.SetProperty(context, arr, index, value, out error);
			Error.Check(context, error, errorHandler);
		}
		public static int Length(this JSArray arr, JSContext context) { return Simple.Value.Length(context, arr); }
		public static JSValue AsValue(this JSArray arr) { return Simple.Value.AsValue(arr); }

		// Function
		public static JSValue Call(this JSFunction fun, JSContext context, JSObject thisObject, JSValue[] args, AutoReleasePool pool, Action<JSScriptException> errorHandler)
		{
			JSScriptException error;
			var result = Simple.Value.CallCreate(context, fun, thisObject, args, args.Length, out error);
			Error.Check(context, error, errorHandler);
			return pool.AutoRelease(result);
		}
		public static JSObject Construct(this JSFunction fun, JSContext context, JSValue[] args, AutoReleasePool pool, Action<JSScriptException> errorHandler)
		{
			JSScriptException error;
			var result = Simple.Value.ConstructCreate(context, fun, args, args.Length, out error);
			Error.Check(context, error, errorHandler);
			return pool.AutoRelease(result);
		}
		public delegate JSValue WrappedCallback(JSValue[] args, out JSValue error);
		public static JSFunction NewCallback(JSContext context, WrappedCallback callback, AutoReleasePool pool, Action<JSScriptException> errorHandler)
		{
			JSScriptException error;
			var result = CreateCallback(context, callback, out error);
			Error.Check(context, error, errorHandler);
			return pool.AutoRelease(result);
		}
		public static JSValue AsValue(this JSFunction fun) { return Simple.Value.AsValue(fun); }

		// Callbacks
		public static Simple.JSCallback CilCallback = new Simple.JSCallback(CilCallbackImpl);

		static JSValue CilCallbackImpl(JSContext context, IntPtr data, JSValue[] args, int numArgs, out JSValue error)
		{
			var wrappedCallback = Handle.Target(data) as WrappedCallback;
			return wrappedCallback(args, out error);
		}
		static extern(DOTNET) JSFunction CreateCallback(JSContext context, WrappedCallback callback, out JSScriptException error)
		{
			return Simple.Value.CreateCallback(context, Handle.Create(callback), CilCallback, out error);
		}
		static extern(CPlusPlus) JSFunction CreateCallback(JSContext context, WrappedCallback callback, out JSScriptException error)
		@{
			return ::CreateJSCallback(
				$0,
				@{Handle.Create(object):Call($1)},
				([] (::JSContext* context, void* data, ::JSValue* const* args, int numArgs, ::JSValue** outError) -> ::JSValue*
				{
					@{WrappedCallback} callback = (@{WrappedCallback})data;

					@{JSValue[]} unoArgs = ::uArray::New(@{JSValue[]:TypeOf}, numArgs, args);
					return @{WrappedCallback:Of(callback):Call(unoArgs, outError)};
				}),
				$2
				);

		@}

		// External
		public static JSExternal NewExternal(JSContext context, IntPtr value, AutoReleasePool pool)
		{
			return pool.AutoRelease(Simple.Value.CreateExternal(context, value));
		}
		public static IntPtr GetValue(this JSExternal ext, JSContext context) { return Simple.Value.GetExternalValue(context, ext); }
		public static JSValue AsValue(this JSExternal ext) { return Simple.Value.AsValue(ext); }

		// ScriptException
		public static void Retain(this JSScriptException jse, JSContext context) { Simple.ScriptException.Retain(context, jse); }
		public static void Release(this JSScriptException jse, JSContext context) { Simple.ScriptException.Release(context, jse); }
		public static JSValue GetException(this JSScriptException jse) { return Simple.ScriptException.GetException(jse); }
		public static string GetMessage(this JSScriptException jse, JSContext context) { return Simple.ScriptException.GetMessage(jse).ToStr(context); }
		public static string GetFileName(this JSScriptException jse, JSContext context) { return Simple.ScriptException.GetFileName(jse).ToStr(context); }
		public static int GetLineNumber(this JSScriptException jse) { return Simple.ScriptException.GetLineNumber(jse); }
		public static string GetStackTrace(this JSScriptException jse, JSContext context) { return Simple.ScriptException.GetStackTrace(jse).ToStr(context); }
		public static string GetSourceLine(this JSScriptException jse, JSContext context) { return Simple.ScriptException.GetSourceLine(jse).ToStr(context); }

		// Debug
		static extern(DOTNET) JSDebugMessageHandler _cilMessageHandler = CilMessageHandlerImpl;
		static extern(DOTNET) void CilMessageHandlerImpl(IntPtr data, JSString message)
		{
			var wrappedCallback = Handle.Target(data) as Action<JSString>;
			wrappedCallback(message);
		}
		public static extern(DOTNET) void SetDebugMessageHandler(JSContext context, Action<JSString> messageHandler)
		{
			Simple.Debug.SetMessageHandler(context, Handle.Create(messageHandler), _cilMessageHandler);
		}
		public static extern(CPlusPlus) void SetDebugMessageHandler(JSContext context, Action<JSString> messageHandler)
		@{
			/*::SetJSDebugMessageHandler(
				$0,
				@{Handle.Create(object):Call($1)},
				([] (void* data, ::JSString* message) -> void
				{
					@{Action<JSString>} handler = (@{Action<JSString>})data;
					@{Action<JSString>:Of(handler).Call(message)};
				}));*/
		@}
	}

	[Require("Header.Include", "include/V8Simple.h")]
	extern(USE_V8) struct AutoReleasePool : IDisposable
	{
		readonly JSContext _context;
		readonly List<JSValue> _pool;
		public AutoReleasePool(JSContext context)
		{
			_context = context;
			_pool = new List<JSValue>();
		}

		public JSValue AutoRelease(JSValue value)
		{
			_pool.Add(value);
			return value;
		}

		public JSObject AutoRelease(JSObject value)
		{
			_pool.Add(value.AsValue());
			return value;
		}

		public JSString AutoRelease(JSString value)
		{
			_pool.Add(value.AsValue());
			return value;
		}

		public JSArray AutoRelease(JSArray value)
		{
			_pool.Add(value.AsValue());
			return value;
		}

		public JSFunction AutoRelease(JSFunction value)
		{
			_pool.Add(value.AsValue());
			return value;
		}

		public JSExternal AutoRelease(JSExternal value)
		{
			_pool.Add(value.AsValue());
			return value;
		}

		public void Dispose()
		{
			foreach (var value in _pool)
				value.Release(_context);
			_pool.Clear();
		}
	}

	[Require("Header.Include", "include/V8Simple.h")]
	extern(USE_V8) static class Error
	{
		public static void Check(JSRuntimeError err)
		{
			if (err != JSRuntimeError.NoError)
				throw new Exception(err.ToString());
		}

		public static void Check(JSContext context, JSScriptException err, Action<JSScriptException> handler)
		{
			if (err != default(JSScriptException))
			{
				try
				{
					handler(err);
				}
				finally
				{
					err.Release(context);
				}
			}
		}
	}
}
