using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.Runtime.InteropServices;
using Uno.Threading;

// Note: Functions with names containing "Create" or "Copy" return results with
// a refcount of 1 that should be released when we're done with them.

namespace Fuse.Scripting.V8.Simple
{
	// -------------------------------------------------------------------------
	// Types
	[DotNetType("Fuse.Scripting.V8.Simple.JSType")]
	extern(USE_V8) enum JSType
	{
		Null,
		Int,
		Double,
		String,
		Bool,
		Object,
		Array,
		Function,
		External,
	}

	[DotNetType("Fuse.Scripting.V8.Simple.JSRuntimeError")]
	extern(USE_V8) enum JSRuntimeError
	{
		NoError,
		InvalidCast,
		StringTooLong,
		TypeError,
	}

	[DotNetType("Fuse.Scripting.V8.Simple.JSCallback")]
	extern(USE_V8) delegate JSValue JSCallback(JSContext context, IntPtr data, JSValue[] args, int numArgs, out JSValue error);

	[DotNetType("Fuse.Scripting.V8.Simple.JSExternalFinalizer")]
	extern(USE_V8) delegate void JSExternalFinalizer(IntPtr external);

	[DotNetType("Fuse.Scripting.V8.Simple.JSCallbackFinalizer")]
	extern(USE_V8) delegate void JSCallbackFinalizer(IntPtr data);

	[DotNetType("Fuse.Scripting.V8.Simple.JSDebugMessageHandler")]
	extern(USE_V8) delegate void JSDebugMessageHandler(IntPtr data, JSString message);

	[DotNetType("Fuse.Scripting.V8.Simple.JSContext")]
	[Set("TypeName", "::JSContext*")]
	[Require("Header.Include", "include/V8Simple.h")]
	extern(USE_V8) struct JSContext
	{
		readonly IntPtr _handle;
	}

	[DotNetType("Fuse.Scripting.V8.Simple.JSValue")]
	[Set("TypeName", "::JSValue*")]
	[Require("Header.Include", "include/V8Simple.h")]
	extern(USE_V8) struct JSValue
	{
		readonly IntPtr _handle;
	}

	[DotNetType("Fuse.Scripting.V8.Simple.JSString")]
	[Set("TypeName", "::JSString*")]
	[Require("Header.Include", "include/V8Simple.h")]
	extern(USE_V8) struct JSString
	{
		readonly IntPtr _handle;
	}

	[DotNetType("Fuse.Scripting.V8.Simple.JSObject")]
	[Set("TypeName", "::JSObject*")]
	[Require("Header.Include", "include/V8Simple.h")]
	extern(USE_V8) struct JSObject
	{
		readonly IntPtr _handle;
	}

	[DotNetType("Fuse.Scripting.V8.Simple.JSArray")]
	[Set("TypeName", "::JSArray*")]
	[Require("Header.Include", "include/V8Simple.h")]
	extern(USE_V8) struct JSArray
	{
		readonly IntPtr _handle;
	}

	[DotNetType("Fuse.Scripting.V8.Simple.JSFunction")]
	[Set("TypeName", "::JSFunction*")]
	[Require("Header.Include", "include/V8Simple.h")]
	extern(USE_V8) struct JSFunction
	{
		readonly IntPtr _handle;
	}

	[DotNetType("Fuse.Scripting.V8.Simple.JSExternal")]
	[Set("TypeName", "::JSExternal*")]
	[Require("Header.Include", "include/V8Simple.h")]
	extern(USE_V8) struct JSExternal
	{
		readonly IntPtr _handle;
	}

	[DotNetType("Fuse.Scripting.V8.Simple.JSScriptException")]
	[Set("TypeName", "::JSScriptException*")]
	[Require("Source.Declaration", "#undef GetMessage")]
	[Require("Header.Include", "include/V8Simple.h")]
	extern(USE_V8) struct JSScriptException
	{
		readonly IntPtr _handle;
		public override bool Equals(object that) { return that is JSScriptException ? this == (JSScriptException)that : false; }
		public override int GetHashCode() { return extern<IntPtr> "*$$".GetHashCode(); }
		public static bool operator ==(JSScriptException e1, JSScriptException e2) { return extern<IntPtr>(e1) "$0" == extern<IntPtr>(e2) "$0"; }
		public static bool operator !=(JSScriptException e1, JSScriptException e2) { return extern<IntPtr>(e1) "$0" != extern<IntPtr>(e2) "$0"; }
	}

	// -------------------------------------------------------------------------
	// Context
	[DotNetType("Fuse.Scripting.V8.Simple.Context")]
	[Require("Header.Include", "include/V8Simple.h")]
	[Require("Source.Include", "@{Handle:Include}")]
	[TargetSpecificImplementation]
	extern(USE_V8) static class Context
	{
		public static extern void Retain(JSContext context) @{ ::RetainJSContext($0); @}
		public static extern void Release(JSContext context) @{ ::ReleaseJSContext($0); @}
		public static extern(DOTNET) JSContext Create(JSCallbackFinalizer callbackFinalizer, JSExternalFinalizer externalFinalizer);
		public static extern(CPlusPlus) JSContext Create()
		@{
			return ::CreateJSContext(
				([] (void* data) -> void
				{
					@{Handle.Free(IntPtr):Call(data)};
				}),
				([] (void* external) -> void
				{
					@{Handle.Free(IntPtr):Call(external)};
				}));

		@}
		public static extern JSValue EvaluateCreate(JSContext context, JSString fileName, JSString code, out JSScriptException error) @{ return ::JSContextEvaluateCreate($0, $1, $2, $3); @}
		public static extern JSObject CopyGlobalObject(JSContext context) @{ return ::JSContextCopyGlobalObject($0); @}
		public static extern string GetV8Version() @{ return ::uString::Ansi(::GetV8Version()); @}
	}

	// -------------------------------------------------------------------------
	// Debug
	[DotNetType("Fuse.Scripting.V8.Simple.Debug")]
	[Require("Header.Include", "include/V8Simple.h")]
	[TargetSpecificImplementation]
	extern(USE_V8) static class Debug
	{
		public static extern(DOTNET) void SetMessageHandler(JSContext context, IntPtr data, JSDebugMessageHandler messageHandler);
		public static extern void SendCommand(JSContext context, string command, int length) @{ 
			//::SendJSDebugCommand($0, (uint16_t*)$1->Ptr(), $2); 
		@}
		public static extern void ProcessMessages(JSContext context) @{ 
			//::ProcessJSDebugMessages($0); 
		@}
	}

	// -------------------------------------------------------------------------
	// Value
	[DotNetType("Fuse.Scripting.V8.Simple.Value")]
	[Require("Header.Include", "include/V8Simple.h")]
	[TargetSpecificImplementation]
	extern(USE_V8) static class Value
	{
		public static extern JSType GetType(JSValue value) @{ return (@{JSType})::GetJSValueType($0); @}
		public static extern void Retain(JSContext context, JSValue value) @{ ::RetainJSValue($0, $1); @}
		public static extern void Release(JSContext context, JSValue value) @{ ::ReleaseJSValue($0, $1); @}
		public static extern int AsInt(JSValue value, out JSRuntimeError error) @{ return ::JSValueAsInt($0, (::JSRuntimeError*)$1); @}
		public static extern double AsDouble(JSValue value, out JSRuntimeError error) @{ return ::JSValueAsDouble($0, (::JSRuntimeError*)$1); @}
		public static extern JSString AsString(JSValue value, out JSRuntimeError error) @{ return ::JSValueAsString($0, (::JSRuntimeError*)$1); @}
		public static extern bool AsBool(JSValue value, out JSRuntimeError error) @{ return ::JSValueAsBool($0, (::JSRuntimeError*)$1); @}
		public static extern JSObject AsObject(JSValue value, out JSRuntimeError error) @{ return ::JSValueAsObject($0, (::JSRuntimeError*)$1); @}
		public static extern JSArray AsArray(JSValue value, out JSRuntimeError error) @{ return ::JSValueAsArray($0, (::JSRuntimeError*)$1); @}
		public static extern JSFunction AsFunction(JSValue value, out JSRuntimeError error) @{ return ::JSValueAsFunction($0, (::JSRuntimeError*)$1); @}
		public static extern JSExternal AsExternal(JSValue value, out JSRuntimeError error) @{ return ::JSValueAsExternal($0, (::JSRuntimeError*)$1); @}
		public static extern bool StrictEquals(JSContext context, JSValue obj1, JSValue obj2) @{ return ::JSValueStrictEquals($0, $1, $2); @}
		// --------------------------------------------------------------------------
		// Primitives
		public static extern JSValue JSNull() @{ return ::JSNull(); @}
		public static extern JSValue CreateInt(int value) @{ return ::CreateJSInt($0); @}
		public static extern JSValue CreateDouble(double value) @{ return ::CreateJSDouble($0); @}
		public static extern JSValue CreateBool(bool value) @{ return ::CreateJSBool($0); @}
		public static extern JSObject CreateExternalArrayBuffer(JSContext context, IntPtr data, int byteLength) @{ return ::CreateExternalJSArrayBuffer($0, $1, $2); @}
		public static extern(DOTNET) JSFunction CreateCallback(JSContext context, IntPtr data, JSCallback callback, out JSScriptException error);
		// --------------------------------------------------------------------------
		// String
		public static extern JSString CreateString(JSContext context, string buffer, int length, out JSRuntimeError error) @{ return ::CreateJSString($0, (uint16_t*)$1->Ptr(), $2, (::JSRuntimeError*)$3); @}
		public static extern int Length(JSContext context, JSString str) @{ return ::JSStringLength($0, $1); @}
		public static extern string ToString(JSContext context, JSString str)
		{
				var len = Length(context, str);
				extern (str, len, context)
				@{
					@{string} result = ::uString::New($1);
					::WriteJSStringBuffer($2, $0, (uint16_t*)result->Ptr(), false);
					return result;
				@}
		}
		public static extern JSValue AsValue(JSString str) @{ return ::JSStringAsValue($0); @}
		// -------------------------------------------------------------------------
		// Object
		public static extern JSValue CopyProperty(JSContext context, JSObject obj, JSString key, out JSScriptException error) @{ return ::CopyJSObjectProperty($0, $1, $2, $3); @}
		public static extern void SetProperty(JSContext context, JSObject obj, JSString key, JSValue value, out JSScriptException error) @{ ::SetJSObjectProperty($0, $1, $2, $3, $4); @}
		public static extern JSArray CopyOwnPropertyNames(JSContext context, JSObject obj, out JSScriptException error) @{ return ::CopyJSObjectOwnPropertyNames($0, $1, $2); @}
		public static extern bool HasProperty(JSContext context, JSObject obj, JSString key, out JSScriptException error) @{ return ::JSObjectHasProperty($0, $1, $2, $3); @}
		public static extern IntPtr GetArrayBufferData(JSContext context, JSObject obj, out JSRuntimeError outError) @{ return ::GetJSObjectArrayBufferData($0, $1, (::JSRuntimeError*)$2); @}
		public static extern JSValue AsValue(JSObject obj) @{ return ::JSObjectAsValue($0); @}
		// -------------------------------------------------------------------------
		// Array
		public static extern JSValue CopyProperty(JSContext context, JSArray arr, int index, out JSScriptException error) @{ return ::CopyJSArrayPropertyAtIndex($0, $1, $2, $3); @}
		public static extern void SetProperty(JSContext context, JSArray arr, int index, JSValue value, out JSScriptException error) @{ ::SetJSArrayPropertyAtIndex($0, $1, $2, $3, $4); @}
		public static extern int Length(JSContext context, JSArray arr) @{ return ::JSArrayLength($0, $1); @}
		public static extern JSValue AsValue(JSArray arr) @{ return ::JSArrayAsValue($0); @}
		// -------------------------------------------------------------------------
		// Function
		public static extern JSValue CallCreate(JSContext context, JSFunction function, JSObject thisObject, JSValue[] args, int numArgs, out JSScriptException error) @{ return ::CallJSFunctionCreate($0, $1, $2, (::JSValue**)$3->Ptr(), $4, $5); @}
		public static extern JSObject ConstructCreate(JSContext context, JSFunction function, JSValue[] args, int numArgs, out JSScriptException error) @{ return ::ConstructJSFunctionCreate($0, $1, (::JSValue**)$2->Ptr(), $3, $4); @}
		public static extern JSValue AsValue(JSFunction fun) @{ return ::JSFunctionAsValue($0); @}
		// -------------------------------------------------------------------------
		// External
		public static extern JSExternal CreateExternal(JSContext context, IntPtr value) @{ return ::CreateJSExternal($0, $1); @}
		public static extern IntPtr GetExternalValue(JSContext context, JSExternal external) @{ return ::GetJSExternalValue($0, $1); @}
		public static extern JSValue AsValue(JSExternal external) @{ return ::JSExternalAsValue($0); @}
	}

	// -------------------------------------------------------------------------
	// Exceptions
	[DotNetType("Fuse.Scripting.V8.Simple.ScriptException")]
	[Require("Header.Include", "include/V8Simple.h")]
	[Require("Source.Declaration", "#undef GetMessage")]
	[TargetSpecificImplementation]
	extern(USE_V8) static class ScriptException
	{
		public static extern void Retain(JSContext context, JSScriptException e) @{ ::RetainJSScriptException($0, $1); @}
		public static extern void Release(JSContext context, JSScriptException e) @{ ::ReleaseJSScriptException($0, $1); @}
		public static extern JSValue GetException(JSScriptException e) @{ return ::GetJSScriptException($0); @}
		public static extern JSString GetMessage(JSScriptException e) @{ return ::GetJSScriptExceptionMessage($0); @}
		public static extern JSString GetFileName(JSScriptException e) @{ return ::GetJSScriptExceptionFileName($0); @}
		public static extern int GetLineNumber(JSScriptException e) @{ return ::GetJSScriptExceptionLineNumber($0); @}
		public static extern JSString GetStackTrace(JSScriptException e) @{ return ::GetJSScriptExceptionStackTrace($0); @}
		public static extern JSString GetSourceLine(JSScriptException e) @{ return ::GetJSScriptExceptionSourceLine($0); @}
	}
}
