#include <include/V8Simple.h>
#include <v8.h>
#include <libplatform/libplatform.h>
#include <natives_blob.h>
#include <snapshot_blob.h>
#include <vector>
#include <cstdlib>
#include <atomic>

struct RefCounted
{
	std::atomic_int _refCount;

	RefCounted()
	{
		_refCount = 1;
	}

	void Retain()
	{
		++_refCount;
	}

	void Release()
	{
		auto newRefCount = --_refCount;
		if (newRefCount == 0)
		{
			delete this;
		}
	}

	virtual ~RefCounted() { }
};

struct ArrayBufferAllocator: v8::ArrayBuffer::Allocator
{
	virtual void* Allocate(size_t length)
	{
		return calloc(length, 1);
	}

	virtual void* AllocateUninitialized(size_t length)
	{
		return malloc(length);
	}

	virtual void Free(void* data, size_t)
	{
		free(data);
	}
};

v8::Platform* _platform = nullptr;

// Using this and not plain v8::Persistents ensures that the references are
// reset in the destructor.
template<class T>
using ResettingPersistent = v8::Persistent<T, v8::CopyablePersistentTraits<T>>;

struct JSContext : RefCounted
{
	const JSCallbackFinalizer CallbackFinalizer;
	const JSExternalFinalizer ExternalFinalizer;
	v8::Isolate* Isolate;
	ResettingPersistent<v8::Context> Handle;
	JSDebugMessageHandler DebugMessageHandler;
	void* DebugMessageHandlerData;

	JSContext(
		JSCallbackFinalizer callbackFinalizer,
		JSExternalFinalizer externalFinalizer)
		: CallbackFinalizer(callbackFinalizer)
		, ExternalFinalizer(externalFinalizer)
		, DebugMessageHandler(nullptr)
		, DebugMessageHandlerData(nullptr)
	{
		if (_platform == nullptr)
		{
			auto* nativesBlobStartupData = new v8::StartupData();
			nativesBlobStartupData->data = reinterpret_cast<const char*>(&natives_blob_bin[0]);
			nativesBlobStartupData->raw_size = natives_blob_bin_len;
			v8::V8::SetNativesDataBlob(nativesBlobStartupData);

			auto* snapshotBlobStartupData = new v8::StartupData();
			snapshotBlobStartupData->data = reinterpret_cast<const char*>(&snapshot_blob_bin[0]);
			snapshotBlobStartupData->raw_size = snapshot_blob_bin_len;
			v8::V8::SetSnapshotDataBlob(snapshotBlobStartupData);

			v8::V8::InitializeICU();
			_platform = v8::platform::NewDefaultPlatform().release();
			v8::V8::InitializePlatform(_platform);
			v8::V8::Initialize();
		}

		static ArrayBufferAllocator arrayBufferAllocator;
		v8::Isolate::CreateParams createParams;
		createParams.array_buffer_allocator = &arrayBufferAllocator;
		Isolate = v8::Isolate::New(createParams);

		v8::Locker locker(Isolate);
		v8::Isolate::Scope isolateScope(Isolate);
		v8::HandleScope handleScope(Isolate);

		auto localContext = v8::Context::New(Isolate);
		v8::Context::Scope contextScope(localContext);

		Handle.Reset(Isolate, localContext);
	}

	virtual ~JSContext() override
	{
		auto oldData = DebugMessageHandlerData;
		DebugMessageHandler = nullptr;
		DebugMessageHandlerData = nullptr;
		if (ExternalFinalizer != nullptr && oldData != nullptr)
			ExternalFinalizer(oldData);
		Handle.Reset();

		Isolate->Dispose();
		Isolate = nullptr;
	}

	inline v8::Local<v8::Context> LocalHandle() { return Handle.Get(Isolate); }
};

struct V8Scope
{
	V8Scope(v8::Isolate* isolate, const ResettingPersistent<v8::Context>& context)
		: Locker(isolate)
		, IsolateScope(isolate)
		, HandleScope(isolate)
		, ContextScope(context.Get(isolate))
	{
	}
	V8Scope(JSContext* context)
		: V8Scope(context->Isolate, context->Handle)
	{
	}
	v8::Locker Locker;
	v8::Isolate::Scope IsolateScope;
	v8::HandleScope HandleScope;
	v8::Context::Scope ContextScope;
};

struct JSValue : RefCounted
{
	virtual JSType Type() const = 0;
};

struct JSInt : JSValue
{
	virtual JSType Type() const override { return JSType::Int; }
	const int Value;
	JSInt(int value) : Value(value) { }
};

struct JSDouble : JSValue
{
	virtual JSType Type() const override { return JSType::Double; }
	const double Value;
	JSDouble(double value) : Value(value) { }
};

struct JSString : JSValue
{
	virtual JSType Type() const override { return JSType::String; }
	const ResettingPersistent<v8::String> Handle;
	JSString(v8::Isolate* isolate, const v8::Local<v8::String>& handle)
		: Handle(isolate, handle)
	{
	}
	inline v8::Local<v8::String> LocalHandle(v8::Isolate* isolate) { return Handle.Get(isolate); }
	inline v8::Local<v8::String> LocalHandle(JSContext* context) { return Handle.Get(context->Isolate); }
};

struct JSBool : JSValue
{
	virtual JSType Type() const override { return JSType::Bool; }
	const bool Value;
	JSBool(bool value) : Value(value) { }
};

struct JSObject : JSValue
{
	virtual JSType Type() const override { return JSType::Object; }
	const ResettingPersistent<v8::Object> Handle;
	JSObject(v8::Isolate* isolate, const v8::Local<v8::Object>& handle)
		: Handle(isolate, handle)
	{
	}
	inline v8::Local<v8::Object> LocalHandle(v8::Isolate* isolate) { return Handle.Get(isolate); }
	inline v8::Local<v8::Object> LocalHandle(JSContext* context) { return Handle.Get(context->Isolate); }
};

struct JSArray : JSValue
{
	virtual JSType Type() const override { return JSType::Array; }
	ResettingPersistent<v8::Array> Handle;
	JSArray(v8::Isolate* isolate, const v8::Local<v8::Array>& handle)
		: Handle(isolate, handle)
	{
	}
	inline v8::Local<v8::Array> LocalHandle(v8::Isolate* isolate) { return Handle.Get(isolate); }
	inline v8::Local<v8::Array> LocalHandle(JSContext* context) { return Handle.Get(context->Isolate); }
};

struct JSFunction : JSValue
{
	virtual JSType Type() const override { return JSType::Function; }
	ResettingPersistent<v8::Function> Handle;
	JSFunction(v8::Isolate* isolate, const v8::Local<v8::Function>& handle)
		: Handle(isolate, handle)
	{
	}
	inline v8::Local<v8::Function> LocalHandle(v8::Isolate* isolate) { return Handle.Get(isolate); }
	inline v8::Local<v8::Function> LocalHandle(JSContext* context) { return Handle.Get(context->Isolate); }
};

struct JSExternal : JSValue
{
	virtual JSType Type() const override { return JSType::External; }
	ResettingPersistent<v8::External> Handle;
	JSExternal(v8::Isolate* isolate, const v8::Local<v8::External>& handle)
		: Handle(isolate, handle)
	{
	}
	inline v8::Local<v8::External> LocalHandle(v8::Isolate* isolate) { return Handle.Get(isolate); }
	inline v8::Local<v8::External> LocalHandle(JSContext* context) { return Handle.Get(context->Isolate); }
};

struct JSScriptException : RefCounted
{
	JSValue* Exception;
	JSString* ErrorMessage;
	JSString* FileName;
	int LineNumber;
	JSString* StackTrace;
	JSString* SourceLine;

	// Note: Assumes that all arguments are retained
	JSScriptException(
		JSValue* exception,
		JSString* errorMessage,
		JSString* fileName,
		int lineNumber,
		JSString* stackTrace,
		JSString* sourceLine)
		: Exception(exception)
		, ErrorMessage(errorMessage)
		, FileName(fileName)
		, LineNumber(lineNumber)
		, StackTrace(stackTrace)
		, SourceLine(sourceLine)
	{
	}

	~JSScriptException()
	{
		if (Exception != nullptr) Exception->Release();
		if (ErrorMessage != nullptr) ErrorMessage->Release();
		if (FileName != nullptr) FileName->Release();
		if (StackTrace != nullptr) StackTrace->Release();
		if (SourceLine != nullptr) SourceLine->Release();
	}
};

template<typename T>
inline static auto TryCatch(
	JSScriptException** outError,
	JSContext* context,
	const V8Scope& scope,
	T inner) -> decltype(inner((v8::TryCatch&)*(v8::TryCatch*)nullptr))
{
	*outError = nullptr;
	try
	{
		v8::TryCatch tryCatch(context->Isolate);
		return inner(tryCatch);
	}
	catch (JSScriptException* exception)
	{
		*outError = exception;
		return decltype(inner((v8::TryCatch&)*(v8::TryCatch*)nullptr))();
	}
}

template<typename T>
inline static auto TryCatch(
	JSScriptException** outError,
	JSContext* context,
	T inner) -> decltype(inner((v8::TryCatch&)*(v8::TryCatch*)nullptr))
{
	V8Scope scope(context);
	return TryCatch(outError, context, scope, inner);
}

static JSValue* Wrap(JSContext* context, const v8::TryCatch& tryCatch, v8::Local<v8::Value> value);

static void Throw(JSContext* context, const v8::TryCatch& tryCatch)
{
	v8::Local<v8::String> emptyString = v8::String::Empty(context->Isolate);

	v8::Local<v8::Message> message = tryCatch.Message();
	v8::Local<v8::String> sourceLine(emptyString);
	v8::Local<v8::String> messageStr(emptyString);
	v8::Local<v8::String> fileName(emptyString);
	int lineNumber = -1;
	auto localContext = context->LocalHandle();
	if (!message.IsEmpty())
	{
		sourceLine = message->GetSourceLine(localContext).FromMaybe(emptyString);
		auto messageStrLocal = message->Get();
		if (!messageStrLocal.IsEmpty())
		{
			messageStr = messageStrLocal;
		}
		fileName = message->GetScriptResourceName()->ToString(localContext).FromMaybe(emptyString);
		lineNumber = message->GetLineNumber(localContext).FromMaybe(-1);
	}

	JSValue* exception = nullptr;
	if (!tryCatch.Exception().IsEmpty())
	{
		v8::TryCatch innerTryCatch(context->Isolate);
		exception = Wrap(context, innerTryCatch, tryCatch.Exception());
	}

	v8::Local<v8::String> stackTrace(
		tryCatch
		.StackTrace(localContext)
		.FromMaybe(emptyString.As<v8::Value>())
		->ToString(localContext)
		.FromMaybe(emptyString));

	throw new JSScriptException(
		exception,
		new JSString(context->Isolate, messageStr),
		new JSString(context->Isolate, fileName),
		lineNumber,
		new JSString(context->Isolate, stackTrace),
		new JSString(context->Isolate, sourceLine));
}

template<class A>
inline static v8::Local<A> FromJust(
	JSContext* context,
	const v8::TryCatch& tryCatch,
	v8::MaybeLocal<A> a)
{
	if (tryCatch.HasCaught() || a.IsEmpty())
	{
		Throw(context, tryCatch);
	}
	return a.ToLocalChecked();
}

template<class A>
inline static A FromJust(
	JSContext* context,
	const v8::TryCatch& tryCatch,
	v8::Maybe<A> a)
{
	if (tryCatch.HasCaught() || a.IsNothing())
	{
		Throw(context, tryCatch);
	}
	return a.FromJust();
}

static JSValue* Wrap(JSContext* context, const v8::TryCatch& tryCatch, v8::Local<v8::Value> value)
{
	if (value->IsUndefined() || value->IsNull())
		return nullptr;
	if (value->IsInt32())
		return new JSInt(FromJust(context, tryCatch, value->Int32Value(context->LocalHandle())));
	if (value->IsNumber())
		return new JSDouble(FromJust(context, tryCatch, value->NumberValue(context->LocalHandle())));
	if (value->IsBoolean())
		return new JSBool(value->BooleanValue(context->Isolate));
	if (value->IsString())
		return new JSString(context->Isolate, FromJust(context, tryCatch, value->ToString(context->LocalHandle())));
	if (value->IsArray())
		return new JSArray(context->Isolate, FromJust(context, tryCatch, value->ToObject(context->LocalHandle())).As<v8::Array>());
	if (value->IsFunction())
		return new JSFunction(context->Isolate, FromJust(context, tryCatch, value->ToObject(context->LocalHandle())).As<v8::Function>());
	if (value->IsExternal())
		return new JSExternal(context->Isolate, value.As<v8::External>());
	if (value->IsObject())
		return new JSObject(context->Isolate, FromJust(context, tryCatch, value->ToObject(context->LocalHandle())));
	return nullptr; // TODO do something good here
}

static v8::Local<v8::Value> Unwrap(v8::Isolate* isolate, JSValue* value)
{
	switch (GetJSValueType(value))
	{
		case JSType::Null:
			return v8::Null(isolate).As<v8::Value>();
		case JSType::Int:
			return v8::Int32::New(isolate, static_cast<JSInt*>(value)->Value);
		case JSType::Double:
			return v8::Number::New(isolate, static_cast<JSDouble*>(value)->Value);
		case JSType::Bool:
			return v8::Boolean::New(isolate, static_cast<JSBool*>(value)->Value);
		case JSType::String:
			return static_cast<JSString*>(value)->LocalHandle(isolate);
		case JSType::Array:
			return static_cast<JSArray*>(value)->LocalHandle(isolate);
		case JSType::Function:
			return static_cast<JSFunction*>(value)->LocalHandle(isolate);
		case JSType::External:
			return static_cast<JSExternal*>(value)->LocalHandle(isolate);
		case JSType::Object:
			return static_cast<JSObject*>(value)->LocalHandle(isolate);
		default: break;
	}
	return v8::Null(isolate).As<v8::Value>(); // TODO do something good here
}

static inline JSValue* WrapMaybe(JSContext* context, const v8::TryCatch& tryCatch, v8::MaybeLocal<v8::Value> value)
{
	return Wrap(context, tryCatch, FromJust(context, tryCatch, value));
}

template<typename T>
inline static T const* data_ptr(const std::vector<T>& v)
{
	return v.size() > 0
		? &*v.begin()
		: nullptr;
}

template<typename T>
inline static T* data_ptr(std::vector<T>& v)
{
	return v.size() > 0
		? &*v.begin()
		: nullptr;
}

// -------------------------------------------------------------------------
// Context
DllPublic void CDecl RetainJSContext(JSContext* context)
{
	if (context != nullptr)
	{
		context->Retain();
	}
}

DllPublic void CDecl ReleaseJSContext(JSContext* context)
{
	if (context != nullptr)
	{
		v8::Locker(context->Isolate);
		context->Release();
	}
}

DllPublic JSContext* CDecl CreateJSContext(
	JSCallbackFinalizer callbackFinalizer,
	JSExternalFinalizer externalFinalizer)
{
	return new JSContext(callbackFinalizer, externalFinalizer);
}

DllPublic JSValue* CDecl JSContextEvaluateCreate(JSContext* context, JSString* fileName, JSString* code, JSScriptException** outError)
{
	return TryCatch(outError, context, [&] (v8::TryCatch& tryCatch)
	{
		v8::ScriptOrigin origin(fileName->LocalHandle(context));
		auto script = FromJust(
			context,
			tryCatch,
			v8::Script::Compile(
				context->LocalHandle(),
				code->LocalHandle(context),
				&origin));

		return WrapMaybe(context, tryCatch, script->Run(context->LocalHandle()));
	});
}

DllPublic JSObject* CDecl JSContextCopyGlobalObject(JSContext* context)
{
	V8Scope scope(context);
	return new JSObject(context->Isolate, context->LocalHandle()->Global());
}

DllPublic const char* CDecl GetV8Version() { return v8::V8::GetVersion(); }

// -------------------------------------------------------------------------
// Value
DllPublic JSType CDecl GetJSValueType(JSValue* value) { return value == nullptr ? JSType::Null : value->Type(); }
DllPublic void CDecl RetainJSValue(JSContext* context, JSValue* value)
{
	if (value != nullptr)
		value->Retain();
}
DllPublic void CDecl ReleaseJSValue(JSContext* context, JSValue* value)
{
	if (value != nullptr && context != nullptr)
	{
		v8::Locker(context->Isolate);
		value->Release();
	}
	else
	{
		// Leak
	}
}

DllPublic int CDecl JSValueAsInt(JSValue* value, JSRuntimeError* outError)
{
	*outError = JSRuntimeError::NoError;
	if (GetJSValueType(value) != JSType::Int)
	{
		*outError = JSRuntimeError::InvalidCast;
		return 0;
	}
	return static_cast<JSInt*>(value)->Value;
}

DllPublic double CDecl JSValueAsDouble(JSValue* value, JSRuntimeError* outError)
{
	*outError = JSRuntimeError::NoError;
	if (GetJSValueType(value) != JSType::Double)
	{
		*outError = JSRuntimeError::InvalidCast;
		return 0.0;
	}
	return static_cast<JSDouble*>(value)->Value;
}

DllPublic JSString* CDecl JSValueAsString(JSValue* value, JSRuntimeError* outError)
{
	*outError = JSRuntimeError::NoError;
	if (GetJSValueType(value) != JSType::String)
	{
		*outError = JSRuntimeError::InvalidCast;
		return nullptr;
	}
	return static_cast<JSString*>(value);
}

DllPublic bool CDecl JSValueAsBool(JSValue* value, JSRuntimeError* outError)
{
	*outError = JSRuntimeError::NoError;
	if (GetJSValueType(value) != JSType::Bool)
	{
		*outError = JSRuntimeError::InvalidCast;
		return false;
	}
	return static_cast<JSBool*>(value)->Value;
}

DllPublic JSObject* CDecl JSValueAsObject(JSValue* value, JSRuntimeError* outError)
{
	*outError = JSRuntimeError::NoError;
	auto type = GetJSValueType(value);
	if (type != JSType::Object && type != JSType::Null)
	{
		*outError = JSRuntimeError::InvalidCast;
		return nullptr;
	}
	return static_cast<JSObject*>(value);
}

DllPublic JSArray* CDecl JSValueAsArray(JSValue* value, JSRuntimeError* outError)
{
	*outError = JSRuntimeError::NoError;
	if (GetJSValueType(value) != JSType::Array)
	{
		*outError = JSRuntimeError::InvalidCast;
		return nullptr;
	}
	return static_cast<JSArray*>(value);
}

DllPublic JSFunction* CDecl JSValueAsFunction(JSValue* value, JSRuntimeError* outError)
{
	*outError = JSRuntimeError::NoError;
	if (GetJSValueType(value) != JSType::Function)
	{
		*outError = JSRuntimeError::InvalidCast;
		return nullptr;
	}
	return static_cast<JSFunction*>(value);
}

DllPublic JSExternal* CDecl JSValueAsExternal(JSValue* value, JSRuntimeError* outError)
{
	*outError = JSRuntimeError::NoError;
	if (GetJSValueType(value) != JSType::External)
	{
		*outError = JSRuntimeError::InvalidCast;
		return nullptr;
	}
	return static_cast<JSExternal*>(value);
}

DllPublic bool CDecl JSValueStrictEquals(JSContext* context, JSValue* obj1, JSValue* obj2)
{
	V8Scope scope(context);
	return Unwrap(context->Isolate, obj1)->StrictEquals(Unwrap(context->Isolate, obj2));
}

// --------------------------------------------------------------------------
// Primitives
DllPublic JSValue* CDecl JSNull() { return nullptr; }
DllPublic JSValue* CDecl CreateJSInt(int value) { return new JSInt(value); }
DllPublic JSValue* CDecl CreateJSDouble(double value) { return new JSDouble(value); }
DllPublic JSValue* CDecl CreateJSBool(bool value) { return new JSBool(value); }

DllPublic JSObject* CDecl CreateExternalJSArrayBuffer(JSContext* context, void* data, int byteLength)
{
	V8Scope scope(context);
	return new JSObject(context->Isolate, v8::ArrayBuffer::New(context->Isolate, data, (size_t)byteLength));
}

DllPublic JSFunction* CDecl CreateJSCallback(JSContext* context, void* data, JSCallback callback, JSScriptException** outError)
{
	return TryCatch(outError, context, [&] (v8::TryCatch& tryCatch)
	{
		struct Closure
		{
			JSContext* context;
			ResettingPersistent<v8::External> finalizer;
			void* data;
			JSCallback callback;
		};
		auto closure = new Closure{context, {}, data, callback};

		auto localClosure = v8::External::New(context->Isolate, closure);
		closure->finalizer.Reset(context->Isolate, localClosure);

		closure->finalizer.SetWeak(
			closure,
			[] (const v8::WeakCallbackInfo<Closure>& data)
			{
				auto closure = data.GetParameter();
				auto f = closure->context->CallbackFinalizer;
				if (f != nullptr)
					f(closure->data);
				closure->finalizer.Reset();
				delete closure;
			},
			v8::WeakCallbackType::kParameter);

		struct AutoReleaser
		{
			const std::vector<JSValue*>& _values;

			~AutoReleaser()
			{
				for (auto v : _values)
				{
					if (v != nullptr)
						v->Release();
				}
			}
		};

		return new JSFunction(context->Isolate,
			FromJust(context, tryCatch, v8::Function::New(
				context->LocalHandle(),
				[] (const v8::FunctionCallbackInfo<v8::Value>& info)
				{
					auto isolate = info.GetIsolate();
					v8::HandleScope handleScope(isolate);
					Closure* closure =
						static_cast<Closure*>(info.Data().
							As<v8::External>()
							->Value());

					auto numArgs = info.Length();
					std::vector<JSValue*> args(numArgs);
					AutoReleaser autoRelease{args};

					try
					{
						{
							v8::TryCatch tryCatch(isolate);
							for (int i = 0; i < numArgs; ++i)
								args[i] = Wrap(closure->context, tryCatch, info[i]);
						}

						JSValue* error = nullptr;
						JSValue* result = closure->callback(closure->context, closure->data, data_ptr(args), numArgs, &error);

						info.GetReturnValue().Set(Unwrap(isolate, result));

						if (result != nullptr)
							result->Release();

						if (error != nullptr)
						{
							auto unwrappedError = Unwrap(isolate, error);
							error->Release();
							isolate->ThrowException(unwrappedError);
						}
					}
					catch (JSScriptException* error)
					{
						auto unwrappedError = Unwrap(isolate, error->Exception);
						error->Release();
						isolate->ThrowException(unwrappedError);
					}
				},
				localClosure.As<v8::Value>())));
	});
}

// --------------------------------------------------------------------------
// String
DllPublic JSString* CDecl CreateJSString(JSContext* context, const uint16_t* buffer, int length, JSRuntimeError* outError)
{
	*outError = JSRuntimeError::NoError;
	V8Scope scope(context);
	auto mstr = v8::String::NewFromTwoByte(context->Isolate, buffer, v8::NewStringType::kNormal, length);
	if (mstr.IsEmpty())
	{
		*outError = JSRuntimeError::StringTooLong;
		return nullptr;
	}
	return new JSString(context->Isolate, mstr.ToLocalChecked());
}

DllPublic int CDecl JSStringLength(JSContext* context, JSString* string)
{
	V8Scope scope(context);
	return string->LocalHandle(context)->Length();
}

DllPublic void CDecl WriteJSStringBuffer(JSContext* context, JSString* string, uint16_t* outBuffer, bool nullTerminate)
{
	V8Scope scope(context);
	string->LocalHandle(context)->Write(context->Isolate, outBuffer, 0, -1, nullTerminate ? v8::String::NO_OPTIONS : v8::String::NO_NULL_TERMINATION);
}

DllPublic JSValue* CDecl JSStringAsValue(JSString* string) { return static_cast<JSValue*>(string); }

// -------------------------------------------------------------------------
// Object
DllPublic JSValue* CDecl CopyJSObjectProperty(JSContext* context, JSObject* obj, JSString* key, JSScriptException** outError)
{
	return TryCatch(outError, context, [&] (v8::TryCatch& tryCatch)
	{
		return WrapMaybe(
			context,
			tryCatch,
			obj->LocalHandle(context)->Get(
				context->LocalHandle(),
				key->LocalHandle(context)));
	});
}

DllPublic void CDecl SetJSObjectProperty(JSContext* context, JSObject* obj, JSString* key, JSValue* value, JSScriptException** outError)
{
	TryCatch(outError, context, [&] (v8::TryCatch& tryCatch)
	{
		FromJust(context, tryCatch, obj->LocalHandle(context)->Set(
			context->LocalHandle(),
			key->LocalHandle(context),
			Unwrap(context->Isolate, value)));
	});
}

DllPublic JSArray* CDecl CopyJSObjectOwnPropertyNames(JSContext* context, JSObject* obj, JSScriptException** outError)
{
	return TryCatch(outError, context, [&] (v8::TryCatch& tryCatch)
	{
		return new JSArray(
			context->Isolate,
			FromJust(
				context,
				tryCatch,
				obj->LocalHandle(context)->GetOwnPropertyNames(context->LocalHandle())));
	});
}

DllPublic bool CDecl JSObjectHasProperty(JSContext* context, JSObject* obj, JSString* key, JSScriptException** outError)
{
	return TryCatch(outError, context, [&] (v8::TryCatch& tryCatch)
	{
		return FromJust(
			context,
			tryCatch,
			obj->LocalHandle(context)->Has(context->LocalHandle(), key->LocalHandle(context)));
	});
}

DllPublic void* CDecl GetJSObjectArrayBufferData(JSContext* context, JSObject* obj, JSRuntimeError* outError)
{
	*outError = JSRuntimeError::NoError;
	V8Scope scope(context);
	auto localObj = obj->LocalHandle(context);
	if (!localObj->IsArrayBuffer())
	{
		*outError = JSRuntimeError::TypeError;
		return nullptr;
	}
	return localObj.As<v8::ArrayBuffer>()->GetContents().Data();
}

DllPublic JSValue* CDecl JSObjectAsValue(JSObject* obj) { return static_cast<JSValue*>(obj); }

// -------------------------------------------------------------------------
// Array
DllPublic JSValue* CDecl CopyJSArrayPropertyAtIndex(JSContext* context, JSArray* arr, int index, JSScriptException** outError)
{
	return TryCatch(outError, context, [&] (v8::TryCatch& tryCatch)
	{
		return WrapMaybe(
			context,
			tryCatch,
			arr->LocalHandle(context)->Get(context->LocalHandle(), index));
	});
}

DllPublic void CDecl SetJSArrayPropertyAtIndex(JSContext* context, JSArray* arr, int index, JSValue* value, JSScriptException** outError)
{
	return TryCatch(outError, context, [&] (v8::TryCatch& tryCatch)
	{
		FromJust(
			context,
			tryCatch,
			arr->LocalHandle(context)->Set(
				context->LocalHandle(),
				static_cast<uint32_t>(index),
				Unwrap(context->Isolate, value)));
	});
}

DllPublic int CDecl JSArrayLength(JSContext* context, JSArray* arr)
{
	V8Scope scope(context);
	return static_cast<int>(arr->LocalHandle(context)->Length());
}

DllPublic JSValue* CDecl JSArrayAsValue(JSArray* arr) { return static_cast<JSValue*>(arr); }

// -------------------------------------------------------------------------
// Function
DllPublic JSValue* CDecl CallJSFunctionCreate(JSContext* context, JSFunction* function, JSObject* thisObject, JSValue* const* args, int numArgs, JSScriptException** outError)
{
	return TryCatch(outError, context, [&] (v8::TryCatch& tryCatch)
	{
		std::vector<v8::Local<v8::Value>> unwrappedArgs(numArgs);

		for (int i = 0; i < numArgs; ++i)
			unwrappedArgs[i] = Unwrap(context->Isolate, args[i]);

		return WrapMaybe(
			context,
			tryCatch,
			function->LocalHandle(context)->Call(
				context->LocalHandle(),
				Unwrap(context->Isolate, thisObject),
				numArgs,
				data_ptr(unwrappedArgs)));

	});
}

DllPublic JSObject* CDecl ConstructJSFunctionCreate(JSContext* context, JSFunction* function, JSValue* const* args, int numArgs, JSScriptException** outError)
{
	return TryCatch(outError, context, [&] (v8::TryCatch& tryCatch)
	{
		std::vector<v8::Local<v8::Value>> unwrappedArgs(numArgs);

		for (int i = 0; i < numArgs; ++i)
			unwrappedArgs[i] = Unwrap(context->Isolate, args[i]);

		return new JSObject(
			context->Isolate,
			FromJust(context, tryCatch, function->LocalHandle(context)->NewInstance(
				context->LocalHandle(),
				numArgs,
				data_ptr(unwrappedArgs))));
	});
}

DllPublic JSValue* CDecl JSFunctionAsValue(JSFunction* fun) { return static_cast<JSValue*>(fun); }

// -------------------------------------------------------------------------
// External
DllPublic JSExternal* CDecl CreateJSExternal(JSContext* context, void* value)
{
	V8Scope scope(context);

	auto localExternal = v8::External::New(context->Isolate, value);

	struct Closure
	{
		ResettingPersistent<v8::External> finalizer;
		JSExternalFinalizer externalFinalizer;
		void* value;
	};

	auto closure = new Closure{{}, context->ExternalFinalizer, value};
	closure->finalizer.Reset(context->Isolate, localExternal);

	closure->finalizer.SetWeak(
		closure,
		[] (const v8::WeakCallbackInfo<Closure>& data)
		{
			auto closure = data.GetParameter();
			if (closure->externalFinalizer != nullptr)
				closure->externalFinalizer(closure->value);
			closure->finalizer.Reset();
			delete closure;
		},
		v8::WeakCallbackType::kParameter);

	return new JSExternal(context->Isolate, localExternal);
}

DllPublic void* CDecl GetJSExternalValue(JSContext* context, JSExternal* external)
{
	V8Scope scope(context);
	return external->LocalHandle(context)->Value();
}

DllPublic JSValue* CDecl JSExternalAsValue(JSExternal* external) { return static_cast<JSValue*>(external); }

// -------------------------------------------------------------------------
// Exceptions
DllPublic void CDecl RetainJSScriptException(JSContext* context, JSScriptException* e)
{
	if (e != nullptr)
	{
		v8::Locker(context->Isolate);
		e->Retain();
	}
}
DllPublic void CDecl ReleaseJSScriptException(JSContext* context, JSScriptException* e)
{
	if (e != nullptr)
	{
		v8::Locker(context->Isolate);
		e->Release();
	}
}
DllPublic JSValue* CDecl GetJSScriptException(JSScriptException* e) { return e->Exception; }
DllPublic JSString* CDecl GetJSScriptExceptionMessage(JSScriptException* e) { return e->ErrorMessage; }
DllPublic JSString* CDecl GetJSScriptExceptionFileName(JSScriptException* e) { return e->FileName; }
DllPublic int CDecl GetJSScriptExceptionLineNumber(JSScriptException* e) { return e->LineNumber; }
DllPublic JSString* CDecl GetJSScriptExceptionStackTrace(JSScriptException* e) { return e->StackTrace; }
DllPublic JSString* CDecl GetJSScriptExceptionSourceLine(JSScriptException* e) { return e->SourceLine; }
/// }
