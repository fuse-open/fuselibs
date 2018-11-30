#pragma once

#include <stdint.h>

#ifdef _MSC_VER
#  ifdef BUILDING_DLL
#    define DllPublic extern "C" __declspec(dllexport)
#  else
#    define DllPublic extern "C" __declspec(dllimport)
#  endif
#  define StdCall __stdcall
#  define CDecl __cdecl
#else
#  define DllPublic extern "C" __attribute__((visibility ("default")))
#  define StdCall
#  define CDecl
#endif

/// using System;
/// using System.Runtime.InteropServices;
/// using System.Text;
/// namespace Fuse.Scripting.V8.Simple
/// {
/// // -------------------------------------------------------------------------
/// // Types
/// public enum JSType
/// {
/// 	Null,
/// 	Int,
/// 	Double,
/// 	String,
/// 	Bool,
/// 	Object,
/// 	Array,
/// 	Function,
/// 	External,
/// }
enum class JSType
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
};
/// public enum JSRuntimeError
/// {
/// 	NoError,
/// 	InvalidCast,
/// 	StringTooLong,
/// 	TypeError,
/// }
enum class JSRuntimeError
{
	NoError,
	InvalidCast,
	StringTooLong,
	TypeError,
};
/// [StructLayout(LayoutKind.Sequential)]
/// public struct JSContext
/// {
/// 	readonly IntPtr _handle;
/// }
struct JSContext;
/// [StructLayout(LayoutKind.Sequential)]
/// public struct JSValue
/// {
/// 	readonly IntPtr _handle;
/// }
struct JSValue;
/// [StructLayout(LayoutKind.Sequential)]
/// public struct JSString
/// {
/// 	readonly IntPtr _handle;
/// }
struct JSString;
/// [StructLayout(LayoutKind.Sequential)]
/// public struct JSObject
/// {
/// 	readonly IntPtr _handle;
/// }
struct JSObject;
/// [StructLayout(LayoutKind.Sequential)]
/// public struct JSArray
/// {
/// 	readonly IntPtr _handle;
/// }
struct JSArray;
/// [StructLayout(LayoutKind.Sequential)]
/// public struct JSFunction
/// {
/// 	readonly IntPtr _handle;
/// }
struct JSFunction;
/// [StructLayout(LayoutKind.Sequential)]
/// public struct JSExternal
/// {
/// 	readonly IntPtr _handle;
/// }
struct JSExternal;
/// [StructLayout(LayoutKind.Sequential)]
/// public struct JSScriptException
/// {
/// 	readonly IntPtr _handle;
/// 	public override bool Equals(object that) { return that is JSScriptException ? this == (JSScriptException)that : false; }
/// 	public override int GetHashCode() { return _handle.GetHashCode(); }
/// 	public static bool operator ==(JSScriptException e1, JSScriptException e2) { return e1._handle == e2._handle; }
/// 	public static bool operator !=(JSScriptException e1, JSScriptException e2) { return e1._handle != e2._handle; }
/// }
struct JSScriptException;
/// public delegate JSValue JSCallback(JSContext context, IntPtr data, [In, MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 3)]JSValue[] args, int numArgs, out JSValue error);
typedef JSValue* (StdCall *JSCallback)(JSContext* context, void* data, JSValue* const* args, int numArgs, JSValue** outError);
/// public delegate void JSExternalFinalizer(IntPtr external);
typedef void (StdCall *JSExternalFinalizer)(void* external);
/// public delegate void JSCallbackFinalizer(IntPtr data);
typedef void (StdCall *JSCallbackFinalizer)(void* data);
/// public delegate void JSDebugMessageHandler(IntPtr data, JSString message);
typedef void (StdCall *JSDebugMessageHandler)(void* data, JSString* message);

/// // -------------------------------------------------------------------------
/// // Context
/// public static class Context
/// {
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="RetainJSContext")]
/// public static extern void Retain(JSContext context);
DllPublic void CDecl RetainJSContext(JSContext* context);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="ReleaseJSContext")]
/// public static extern void Release(JSContext context);
DllPublic void CDecl ReleaseJSContext(JSContext* context);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="CreateJSContext")]
/// public static extern JSContext Create([MarshalAs(UnmanagedType.FunctionPtr)]JSCallbackFinalizer callbackFinalizer, [MarshalAs(UnmanagedType.FunctionPtr)]JSExternalFinalizer externalFinalizer);
DllPublic JSContext* CDecl CreateJSContext(JSCallbackFinalizer callbackFinalizer, JSExternalFinalizer externalFinalizer);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="JSContextEvaluateCreate")]
/// public static extern JSValue EvaluateCreate(JSContext context, JSString fileName, JSString code, out JSScriptException error);
DllPublic JSValue* CDecl JSContextEvaluateCreate(JSContext* context, JSString* fileName, JSString* code, JSScriptException** outError);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="JSContextCopyGlobalObject")]
/// public static extern JSObject CopyGlobalObject(JSContext context);
DllPublic JSObject* CDecl JSContextCopyGlobalObject(JSContext* context);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="GetV8Version")]
/// public static extern IntPtr GetV8VersionPtr();
/// public static string GetV8Version() { return Marshal.PtrToStringAnsi(GetV8VersionPtr()); }
DllPublic const char* CDecl GetV8Version();
/// }

/// // -------------------------------------------------------------------------
/// // Value
/// public static class Value
/// {
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="GetJSValueType")]
/// public static extern JSType GetType(JSValue value);
DllPublic JSType CDecl GetJSValueType(JSValue* value);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="RetainJSValue")]
/// public static extern void Retain(JSContext context, JSValue value);
DllPublic void CDecl RetainJSValue(JSContext* context, JSValue* value);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="ReleaseJSValue")]
/// public static extern void Release(JSContext context, JSValue value);
DllPublic void CDecl ReleaseJSValue(JSContext* context, JSValue* value);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="JSValueAsInt")]
/// public static extern int AsInt(JSValue value, out JSRuntimeError error);
DllPublic int CDecl JSValueAsInt(JSValue* value, JSRuntimeError* outError);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="JSValueAsDouble")]
/// public static extern double AsDouble(JSValue value, out JSRuntimeError error);
DllPublic double CDecl JSValueAsDouble(JSValue* value, JSRuntimeError* outError);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="JSValueAsString")]
/// public static extern JSString AsString(JSValue value, out JSRuntimeError error);
DllPublic JSString* CDecl JSValueAsString(JSValue* value, JSRuntimeError* outError);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="JSValueAsBool")]
/// [return: MarshalAs(UnmanagedType.I1)]
/// public static extern bool AsBool(JSValue value, out JSRuntimeError error);
DllPublic bool CDecl JSValueAsBool(JSValue* value, JSRuntimeError* outError);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="JSValueAsObject")]
/// public static extern JSObject AsObject(JSValue value, out JSRuntimeError error);
DllPublic JSObject* CDecl JSValueAsObject(JSValue* value, JSRuntimeError* outError);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="JSValueAsArray")]
/// public static extern JSArray AsArray(JSValue value, out JSRuntimeError error);
DllPublic JSArray* CDecl JSValueAsArray(JSValue* value, JSRuntimeError* outError);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="JSValueAsFunction")]
/// public static extern JSFunction AsFunction(JSValue value, out JSRuntimeError error);
DllPublic JSFunction* CDecl JSValueAsFunction(JSValue* value, JSRuntimeError* outError);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="JSValueAsExternal")]
/// public static extern JSExternal AsExternal(JSValue value, out JSRuntimeError error);
DllPublic JSExternal* CDecl JSValueAsExternal(JSValue* value, JSRuntimeError* outError);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="JSValueStrictEquals")]
/// [return: MarshalAs(UnmanagedType.I1)]
/// public static extern bool StrictEquals(JSContext context, JSValue obj1, JSValue obj2);
DllPublic bool CDecl JSValueStrictEquals(JSContext* context, JSValue* obj1, JSValue* obj2);

/// // --------------------------------------------------------------------------
/// // Primitives
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="JSNull")]
/// public static extern JSValue JSNull();
DllPublic JSValue* CDecl JSNull();
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="CreateJSInt")]
/// public static extern JSValue CreateInt(int value);
DllPublic JSValue* CDecl CreateJSInt(int value);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="CreateJSDouble")]
/// public static extern JSValue CreateDouble(double value);
DllPublic JSValue* CDecl CreateJSDouble(double value);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="CreateJSBool")]
/// public static extern JSValue CreateBool([MarshalAs(UnmanagedType.I1)]bool value);
DllPublic JSValue* CDecl CreateJSBool(bool value);
///// Not memory managed; add an External property if data needs to be retained
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="CreateExternalJSArrayBuffer")]
/// public static extern JSObject CreateExternalArrayBuffer(JSContext context, IntPtr data, int byteLength);
DllPublic JSObject* CDecl CreateExternalJSArrayBuffer(JSContext* context, void* data, int byteLength);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="CreateJSCallback")]
/// public static extern JSFunction CreateCallback(JSContext context, IntPtr data, [MarshalAs(UnmanagedType.FunctionPtr)]JSCallback callback, out JSScriptException error);
DllPublic JSFunction* CDecl CreateJSCallback(JSContext* context, void* data, JSCallback callback, JSScriptException** outError);

/// // --------------------------------------------------------------------------
/// // String
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="CreateJSString")]
/// public static extern JSString CreateString(JSContext context, [MarshalAs(UnmanagedType.LPWStr, SizeParamIndex = 2)]string buffer, int length, out JSRuntimeError error);
DllPublic JSString* CDecl CreateJSString(JSContext* context, const uint16_t* buffer, int length, JSRuntimeError* outError);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="JSStringLength")]
/// public static extern int Length(JSContext context, JSString str);
DllPublic int CDecl JSStringLength(JSContext* context, JSString* string);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="WriteJSStringBuffer")]
/// public static extern void Write(JSContext context, JSString str, [Out, MarshalAs(UnmanagedType.LPWStr)]StringBuilder buffer, [MarshalAs(UnmanagedType.I1)]bool nullTerminate);
DllPublic void CDecl WriteJSStringBuffer(JSContext* context, JSString* string, uint16_t* outBuffer, bool nullTerminate);
/// public static string ToString(JSContext context, JSString str)
/// {
/// 	var sb = new StringBuilder(Length(context, str) + 1);
/// 	Write(context, str, sb, true);
/// 	return sb.ToString();
/// }

/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="JSStringAsValue")]
/// public static extern JSValue AsValue(JSString str);
DllPublic JSValue* CDecl JSStringAsValue(JSString* string);

/// // -------------------------------------------------------------------------
/// // Object
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="CopyJSObjectProperty")]
/// public static extern JSValue CopyProperty(JSContext context, JSObject obj, JSString key, out JSScriptException error);
DllPublic JSValue* CDecl CopyJSObjectProperty(JSContext* context, JSObject* obj, JSString* key, JSScriptException** outError);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="SetJSObjectProperty")]
/// public static extern void SetProperty(JSContext context, JSObject obj, JSString key, JSValue value, out JSScriptException error);
DllPublic void CDecl SetJSObjectProperty(JSContext* context, JSObject* obj, JSString* key, JSValue* value, JSScriptException** outError);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="CopyJSObjectOwnPropertyNames")]
/// public static extern JSArray CopyOwnPropertyNames(JSContext context, JSObject obj, out JSScriptException error);
DllPublic JSArray* CDecl CopyJSObjectOwnPropertyNames(JSContext* context, JSObject* obj, JSScriptException** outError);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="JSObjectHasProperty")]
/// [return: MarshalAs(UnmanagedType.I1)]
/// public static extern bool HasProperty(JSContext context, JSObject obj, JSString key, out JSScriptException error);
DllPublic bool CDecl JSObjectHasProperty(JSContext* context, JSObject* obj, JSString* key, JSScriptException** outError);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="GetJSObjectArrayBufferData")]
/// public static extern IntPtr GetArrayBufferData(JSContext context, JSObject obj, out JSRuntimeError outError);
DllPublic void* CDecl GetJSObjectArrayBufferData(JSContext* context, JSObject* obj, JSRuntimeError* outError);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="JSObjectAsValue")]
/// public static extern JSValue AsValue(JSObject obj);
DllPublic JSValue* CDecl JSObjectAsValue(JSObject* obj);

/// // -------------------------------------------------------------------------
/// // Array
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="CopyJSArrayPropertyAtIndex")]
/// public static extern JSValue CopyProperty(JSContext context, JSArray arr, int index, out JSScriptException error);
DllPublic JSValue* CDecl CopyJSArrayPropertyAtIndex(JSContext* context, JSArray* arr, int index, JSScriptException** outError);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="SetJSArrayPropertyAtIndex")]
/// public static extern void SetProperty(JSContext context, JSArray arr, int index, JSValue value, out JSScriptException error);
DllPublic void CDecl SetJSArrayPropertyAtIndex(JSContext* context, JSArray* arr, int index, JSValue* value, JSScriptException** outError);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="JSArrayLength")]
/// public static extern int Length(JSContext context, JSArray arr);
DllPublic int CDecl JSArrayLength(JSContext* context, JSArray* arr);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="JSArrayAsValue")]
/// public static extern JSValue AsValue(JSArray arr);
DllPublic JSValue* CDecl JSArrayAsValue(JSArray* arr);

/// // -------------------------------------------------------------------------
/// // Function
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="CallJSFunctionCreate")]
/// public static extern JSValue CallCreate(JSContext context, JSFunction function, JSObject thisObject, [In, MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 4)]JSValue[] args, int numArgs, out JSScriptException error);
DllPublic JSValue* CDecl CallJSFunctionCreate(JSContext* context, JSFunction* function, JSObject* thisObject, JSValue* const* args, int numArgs, JSScriptException** outError);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="ConstructJSFunctionCreate")]
/// public static extern JSObject ConstructCreate(JSContext context, JSFunction function, [In, MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 3)]JSValue[] args, int numArgs, out JSScriptException error);
DllPublic JSObject* CDecl ConstructJSFunctionCreate(JSContext* context, JSFunction* function, JSValue* const* args, int numArgs, JSScriptException** outError);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="JSFunctionAsValue")]
/// public static extern JSValue AsValue(JSFunction fun);
DllPublic JSValue* CDecl JSFunctionAsValue(JSFunction* fun);

/// // -------------------------------------------------------------------------
/// // External
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="CreateJSExternal")]
/// public static extern JSExternal CreateExternal(JSContext context, IntPtr value);
DllPublic JSExternal* CDecl CreateJSExternal(JSContext* context, void* value);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="GetJSExternalValue")]
/// public static extern IntPtr GetExternalValue(JSContext context, JSExternal external);
DllPublic void* CDecl GetJSExternalValue(JSContext* context, JSExternal* external);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="JSExternalAsValue")]
/// public static extern JSValue AsValue(JSExternal external);
DllPublic JSValue* CDecl JSExternalAsValue(JSExternal* external);
/// }

/// // -------------------------------------------------------------------------
/// // Exceptions
/// public static class ScriptException
/// {
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="RetainJSScriptException")]
/// public static extern void Retain(JSContext context, JSScriptException e);
DllPublic void CDecl RetainJSScriptException(JSContext* context, JSScriptException* e);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="ReleaseJSScriptException")]
/// public static extern void Release(JSContext context, JSScriptException e);
DllPublic void CDecl ReleaseJSScriptException(JSContext* context, JSScriptException* e);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="GetJSScriptException")]
/// public static extern JSValue GetException(JSScriptException e);
DllPublic JSValue* CDecl GetJSScriptException(JSScriptException* e);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="GetJSScriptExceptionMessage")]
/// public static extern JSString GetMessage(JSScriptException e);
DllPublic JSString* CDecl GetJSScriptExceptionMessage(JSScriptException* e);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="GetJSScriptExceptionFileName")]
/// public static extern JSString GetFileName(JSScriptException e);
DllPublic JSString* CDecl GetJSScriptExceptionFileName(JSScriptException* e);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="GetJSScriptExceptionLineNumber")]
/// public static extern int GetLineNumber(JSScriptException e);
DllPublic int CDecl GetJSScriptExceptionLineNumber(JSScriptException* e);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="GetJSScriptExceptionStackTrace")]
/// public static extern JSString GetStackTrace(JSScriptException e);
DllPublic JSString* CDecl GetJSScriptExceptionStackTrace(JSScriptException* e);
/// [DllImport("V8Simple.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint="GetJSScriptExceptionSourceLine")]
/// public static extern JSString GetSourceLine(JSScriptException e);
DllPublic JSString* CDecl GetJSScriptExceptionSourceLine(JSScriptException* e);
/// }

/// }
