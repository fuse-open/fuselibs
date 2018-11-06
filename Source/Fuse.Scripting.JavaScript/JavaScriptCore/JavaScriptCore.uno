using Uno;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Scripting.JavaScriptCore
{
	[Require("Source.Include", "JavaScriptCore/JSValueRef.h")]
	[Set("TypeName", "::JSValueRef")]
	[Set("DefaultValue", "NULL")]
	extern(USE_JAVASCRIPTCORE) struct JSValueRef
	{
		public static bool operator==(JSValueRef v1, JSValueRef v2) @{ return v1 == v2; @}
		public static bool operator!=(JSValueRef v1, JSValueRef v2) @{ return v1 != v2; @}

		// ~Retain
		public void Protect(JSContextRef ctx)
		@{
			::JSValueProtect($0, *$$);
		@}

		// ~Release
		public void Unprotect(JSContextRef ctx)
		@{
			::JSValueUnprotect($0, *$$);
		@}

		public void DeferedUnprotect()
		{
			Fuse.Reactive.JavaScript.Worker.Invoke(DeferedUnprotectInner);
		}

		void DeferedUnprotectInner(Fuse.Scripting.Context ctx)
		{
			var ctxRef = ((Context)ctx)._context;
			Unprotect(ctxRef);
		}

		public JSObjectRef GetJSObjectRef(JSContextRef ctx)
		{
			assert IsObject(ctx);
			@{
				return (@{JSObjectRef})*$$;
			@}
		}

		public JSType GetType(JSContextRef ctx)
		@{
			::JSType type = ::JSValueGetType($0, *$$);
			switch (type)
			{
				case ::kJSTypeUndefined: return @{JSType.Undefined};
				case ::kJSTypeNull: return @{JSType.Null};
				case ::kJSTypeBoolean: return @{JSType.Boolean};
				case ::kJSTypeNumber: return @{JSType.Number};
				case ::kJSTypeString: return @{JSType.String};
				case ::kJSTypeObject: return @{JSType.Object};
				default: return @{JSType.FlipTheTable};
			}
		@}

		JSStringRef ToStringCopy(JSContextRef ctx, out JSValueRef exception)
		@{
			return ::JSValueToStringCopy($0, *$$, $1);
		@}

		public string ToString(JSContextRef ctx, Action<JSValueRef> onException)
		{
			JSValueRef exception = default(JSValueRef);
			using (var strRef = ToStringCopy(ctx, out exception))
			{
				if (exception != default(JSValueRef))
					onException(exception);
				return strRef.ToString();
			}
		}

		public bool IsObject(JSContextRef ctx)
		@{
			return ::JSValueIsObject($0, *$$);
		@}

		public bool IsInstanceOfConstructor(JSContextRef ctx, JSObjectRef constructor, Action<JSValueRef> onException)
		@{
			::JSValueRef exception = NULL;
			bool result = ::JSValueIsInstanceOfConstructor($0, *$$, $1, &exception);
			if (exception != NULL)
				@{Action<JSValueRef>:Of($2):Call(exception)};
			return result;
		@}

		static JSValueRef MakeString(JSContextRef ctx, JSStringRef str)
		@{
			return ::JSValueMakeString($0, $1);
		@}

		public static JSValueRef MakeString(JSContextRef ctx, string str)
		{
			if (str == null) throw new ArgumentNullException(nameof(str));
			using (var strRef = JSStringRef.Create(str))
			{
				return MakeString(ctx, strRef);
			}
		}

		public static JSValueRef MakeNull(JSContextRef ctx)
		@{
			return ::JSValueMakeNull($0);
		@}

		public static JSValueRef MakeNumber(JSContextRef ctx, double number)
		@{
			return ::JSValueMakeNumber($0, $1);
		@}

		public static JSValueRef MakeBoolean(JSContextRef ctx, bool boolean)
		@{
			return ::JSValueMakeBoolean($0, $1);
		@}

		public bool ToBoolean(JSContextRef ctx)
		@{
			return ::JSValueToBoolean($0, *$$);
		@}

		public double ToNumber(JSContextRef ctx, Action<JSValueRef> onException)
		@{
			::JSValueRef exception = NULL;
			double result = ::JSValueToNumber($0, *$$, &exception);
			if (exception != NULL)
				@{Action<JSValueRef>:Of($1):Call(exception)};
			return result;
		@}
	}

	extern(USE_JAVASCRIPTCORE) enum JSType
	{
		Undefined,
		Null,
		Boolean,
		Number,
		String,
		Object,
		FlipTheTable,
	}

	[Set("Include", "JavaScriptCore/JSStringRef.h")]
	[Set("TypeName", "::JSStringRef")]
	[Set("DefaultValue", "NULL")]
	extern(USE_JAVASCRIPTCORE) struct JSStringRef : IDisposable
	{
		public static JSStringRef Create(string str)
		@{
			return ::JSStringCreateWithCharacters((const JSChar*)$0->Ptr(), $0->Length());
		@}

		public void Dispose()
		@{
			::JSStringRelease(*$$);
		@}

		public override string ToString()
		@{
			size_t len = ::JSStringGetLength(*$$);
			@{string} result = ::uString::New((int)len);
			::memcpy((void*)result->Ptr(), ::JSStringGetCharactersPtr(*$$), sizeof(@{char}) * len);
			return result;
		@}
	}

	[Set("Include", "JavaScriptCore/JSObjectRef.h")]
	[Set("TypeName", "::JSObjectRef")]
	[Set("DefaultValue", "NULL")]
	extern(USE_JAVASCRIPTCORE) struct JSObjectRef
	{
		public static bool operator==(JSObjectRef o1, JSObjectRef o2) @{ return o1 == o2; @}
		public static bool operator!=(JSObjectRef o1, JSObjectRef o2) @{ return o1 != o2; @}

		JSValueRef GetProperty(JSContextRef ctx, JSStringRef propertyName, out JSValueRef exception)
		@{
			return ::JSObjectGetProperty($0, *$$, $1, $2);
		@}

		public JSValueRef GetProperty(JSContextRef ctx, string propertyName, Action<JSValueRef> onException)
		{
			if (propertyName == null) throw new ArgumentNullException(nameof(propertyName));
			using (var strRef = JSStringRef.Create(propertyName))
			{
				JSValueRef exception = default(JSValueRef);
				var result = GetProperty(ctx, strRef, out exception);
				if (exception != default(JSValueRef))
					onException(exception);
				return result;
			}
		}

		void SetProperty(JSContextRef ctx, JSStringRef propertyName, JSValueRef value, out JSValueRef exception)
		@{
			::JSObjectSetProperty($0, *$$, $1, $2, ::kJSPropertyAttributeNone, $3);
		@}

		public void SetProperty(JSContextRef ctx, string propertyName, JSValueRef value, Action<JSValueRef> onException)
		{
			if (propertyName == null) throw new ArgumentNullException(nameof(propertyName));
			using (var strRef = JSStringRef.Create(propertyName))
			{
				JSValueRef exception = default(JSValueRef);
				SetProperty(ctx, strRef, value, out exception);
				if (exception != default(JSValueRef))
					onException(exception);
			}
		}

		JSValueRef GetPropertyAtIndex(JSContextRef ctx, int index, out JSValueRef exception)
		@{
			return ::JSObjectGetPropertyAtIndex($0, *$$, (unsigned)$1, $2);
		@}

		public JSValueRef GetPropertyAtIndex(JSContextRef ctx, int index, Action<JSValueRef> onException)
		{
			JSValueRef exception = default(JSValueRef);
			var result = GetPropertyAtIndex(ctx, index, out exception);
			if (exception != default(JSValueRef))
				onException(exception);
			return result;
		}

		void SetPropertyAtIndex(JSContextRef ctx, int index, JSValueRef value, out JSValueRef exception)
		@{
			::JSObjectSetPropertyAtIndex($0, *$$, (unsigned)$1, $2, $3);
		@}

		public void SetPropertyAtIndex(JSContextRef ctx, int index, JSValueRef value, Action<JSValueRef> onException)
		{
			JSValueRef exception = default(JSValueRef);
			SetPropertyAtIndex(ctx, index, value, out exception);
			if (exception != default(JSValueRef))
				onException(exception);
		}

		public bool HasProperty(JSContextRef ctx, JSStringRef propertyName)
		@{
			return ::JSObjectHasProperty($0, *$$, $1);
		@}

		public bool HasProperty(JSContextRef ctx, string propertyName)
		{
			if (propertyName == null) throw new ArgumentNullException(nameof(propertyName));
			using (var strRef = JSStringRef.Create(propertyName))
			{
				return HasProperty(ctx, strRef);
			}
		}

		public JSValueRef GetJSValueRef()
		@{
			return (@{JSValueRef})*$$;
		@}

		public object GetPrivate()
		@{
			return (@{object})::JSObjectGetPrivate(*$$);
		@}

		public bool SetPrivate(object data)
		@{
			return ::JSObjectSetPrivate(*$$, $0);
		@}

		public void SetPrototype(JSContextRef ctx, JSValueRef value)
		@{
			::JSObjectSetPrototype($0, *$$, $1);
		@}

		public JSPropertyNameArray CopyPropertyNames(JSContextRef ctx)
		@{
			return ::JSObjectCopyPropertyNames($0, *$$);
		@}

		public static JSObjectRef Make(JSContextRef ctx, JSClassRef classRef = default(JSClassRef), object data = null)
		@{
			::uRetain($2);
			return ::JSObjectMake($0, $1, $2);
		@}

		public JSValueRef CallAsFunction(
			JSContextRef ctx,
			JSObjectRef thisObject,
			JSValueRef[] arguments,
			Action<JSValueRef> onException)
		@{
			::JSValueRef exception = NULL;
			::JSValueRef result = JSObjectCallAsFunction(
				$0,
				*$$,
				$1,
				(size_t)$2->Length(),
				(::JSValueRef*)$2->Ptr(),
				&exception);
			if (exception != NULL)
				@{Action<JSValueRef>:Of($3):Call(exception)};
			return result;
		@}

		public JSObjectRef CallAsConstructor(
			JSContextRef ctx,
			JSValueRef[] arguments,
			Action<JSValueRef> onException)
		@{
			::JSValueRef exception = NULL;
			::JSObjectRef result = ::JSObjectCallAsConstructor(
				$0,
				*$$,
				(size_t)$1->Length(),
				(::JSValueRef*)$1->Ptr(),
				&exception);
			if (exception != NULL)
				@{Action<JSValueRef>:Of($2):Call(exception)};
			return result;
		@}
	}

	[Set("Include", "JavaScriptCore/JSObjectRef.h")]
	[Set("TypeName", "::JSPropertyNameArrayRef")]
	[Set("DefaultValue", "NULL")]
	extern(USE_JAVASCRIPTCORE) struct JSPropertyNameArray: IDisposable
	{
		public int GetCount()
		@{
			return (@{int})::JSPropertyNameArrayGetCount(*$$);
		@}

		public JSStringRef this[int index]
		{
			get
			@{
				return ::JSPropertyNameArrayGetNameAtIndex(*$$, (size_t)$0);
			@}
		}

		public void Dispose()
		@{
			::JSPropertyNameArrayRelease(*$$);
		@}
	}

	[Require("Source.Include", "JavaScriptCore/JSBase.h")]
	[Set("Include", "JavaScriptCore/JSContextRef.h")]
	[Set("TypeName", "::JSContextRef")]
	[Set("DefaultValue", "NULL")]
	extern(USE_JAVASCRIPTCORE) struct JSContextRef : IDisposable
	{
		public static JSContextRef Create()
		@{
			return (@{JSContextRef})::JSGlobalContextCreate(NULL);
		@}

		public void Dispose()
		@{
			::JSGlobalContextRelease((::JSGlobalContextRef)*$$);
		@}

		public JSObjectRef GlobalObject
		{
			get
			@{
				return ::JSContextGetGlobalObject(*$$);
			@}
		}

		JSValueRef EvaluateScript(
			JSStringRef script,
			JSObjectRef thisObject,
			JSStringRef sourceURL,
			int startingLineNumber,
			out JSValueRef exception)
		@{
			return ::JSEvaluateScript(*$$, $0, $1, $2, $3, $4);
		@}

		public JSValueRef EvaluateScript(
			string script,
			JSObjectRef thisObject,
			string sourceURL,
			int startingLineNumber,
			Action<JSValueRef> onException)
		{
			if (script == null) throw new ArgumentNullException(nameof(script));
			if (sourceURL == null) throw new ArgumentNullException(nameof(sourceURL));
			using (var scriptRef = JSStringRef.Create(script))
			using (var sourceRef = JSStringRef.Create(sourceURL))
			{
				JSValueRef exception = default(JSValueRef);
				JSValueRef result = EvaluateScript(
					scriptRef,
					thisObject,
					sourceRef,
					startingLineNumber,
					out exception);
				if (exception != default(JSValueRef))
					onException(exception);
				return result;
			}
			return default(JSValueRef); // Satisfy Uno
		}
	}

	[Set("Include", "JavaScriptCore/JSObjectRef.h")]
	[Set("TypeName", "::JSClassRef")]
	[Set("DefaultValue", "NULL")]
	extern(USE_JAVASCRIPTCORE) struct JSClassRef : IDisposable
	{
		public static JSClassRef CreateUnoFinalizer()
		@{
			::JSClassDefinition classDef = kJSClassDefinitionEmpty;
			classDef.finalize = (::JSObjectFinalizeCallback)
			[] (::JSObjectRef obj) -> void
			{
				@{object} unoObj = (@{object})JSObjectGetPrivate(obj);
				::uRelease(unoObj);
			};
			return ::JSClassCreate(&classDef);
		@}

		public delegate JSValueRef RawCallback(JSValueRef[] args, out JSValueRef exception);

		public static JSClassRef CreateUnoCallback()
		@{
			::JSClassDefinition classDef = kJSClassDefinitionEmpty;
			classDef.finalize = (::JSObjectFinalizeCallback) [] (::JSObjectRef obj) -> void
			{
				@{object} unoObj = (@{object})JSObjectGetPrivate(obj);
				::uRelease(unoObj);
			};

			classDef.callAsFunction = (::JSObjectCallAsFunctionCallback) [] (
				::JSContextRef ctx,
				::JSObjectRef function,
				::JSObjectRef thisObject,
				size_t argumentCount,
				const ::JSValueRef arguments[],
				::JSValueRef* exception) -> ::JSValueRef
			{
				@{RawCallback} unoDelegate = (@{RawCallback})JSObjectGetPrivate(function);
				@{JSValueRef[]} unoArguments = @{JSValueRef[]:New((int)argumentCount)};
				for (int i = 0; i < argumentCount; ++i)
				{
					@{JSValueRef[]:Of(unoArguments):Set(i, arguments[i])};
				}

				return @{RawCallback:Of(unoDelegate):Call(unoArguments, exception)};
			};

			classDef.callAsConstructor = (::JSObjectCallAsConstructorCallback) [] (
				::JSContextRef ctx,
				::JSObjectRef constructor,
				size_t argumentCount,
				const ::JSValueRef arguments[],
				::JSValueRef* exception) -> ::JSObjectRef
			{
				@{RawCallback} unoDelegate = (@{RawCallback})JSObjectGetPrivate(constructor);
				@{JSValueRef[]} unoArguments = @{JSValueRef[]:New((int)argumentCount)};
				for (int i = 0; i < argumentCount; ++i)
				{
					@{JSValueRef[]:Of(unoArguments):Set(i, arguments[i])};
				}

				::JSValueRef result = @{RawCallback:Of(unoDelegate):Call(unoArguments, exception)};
				if (!::JSValueIsObject(ctx, result))
				{
					const char* errorStr
						= "Scripting.Callback called as a constructor returned a non-object.";
					::uString* unoErrorStr = ::uString::Ansi(errorStr);
					*exception = @{JSValueRef.MakeString(JSContextRef, string):Call(ctx, unoErrorStr)};
					return NULL;
				}
				return (::JSObjectRef)result;
			};

			return ::JSClassCreate(&classDef);
		@}

		public void Dispose()
		@{
			::JSClassRelease(*$$);
		@}
	}

	[Require("Source.Include", "JavaScriptCore/JSTypedArrayInclude.h")]
	extern(USE_JAVASCRIPTCORE) static class JSTypedArray
	{
		public static JSObjectRef TryMakeArrayBufferWithBytes(JSContextRef ctx, byte[] bytes, Action<JSValueRef> onException)
		@{
			// Check for sufficient base SDK version
			#ifdef JAVASCRIPTCORE_ARRAYBUFFER_SUPPORT
			// Check for runtime availability (running on earlier iOS versions)
			if (&::JSObjectMakeArrayBufferWithBytesNoCopy != NULL)
			{
				::JSValueRef exception = NULL;
				::uRetain($1);
				::JSObjectRef result = ::JSObjectMakeArrayBufferWithBytesNoCopy(
					$0,
					$1->Ptr(),
					$1->Length(),
					(::JSTypedArrayBytesDeallocator)[] (void* bytes, void* deallocatorContext) -> void
					{
						::uRelease((@{byte[]})deallocatorContext);
					},
					$1, // deallocatorContext
					&exception);
				if (exception != NULL)
					@{Action<JSValueRef>:Of($2):Call(exception)};
				return result;
			}
			#endif
			return NULL;
		@}

		public static byte[] TryCopyArrayBufferBytes(JSContextRef ctx, JSObjectRef obj, Action<JSValueRef> onException)
		@{
			#ifdef JAVASCRIPTCORE_ARRAYBUFFER_SUPPORT
			if (&::JSObjectGetArrayBufferBytesPtr != NULL &&
				&::JSObjectGetArrayBufferByteLength != NULL)
			{
				::JSValueRef exception = NULL;
				size_t length = ::JSObjectGetArrayBufferByteLength($0, $1, &exception);
				if (exception != NULL)
					@{Action<JSValueRef>:Of($2):Call(exception)};
				void* bytesPtr = ::JSObjectGetArrayBufferBytesPtr($0, $1, &exception);
				if (exception != NULL)
					@{Action<JSValueRef>:Of($2):Call(exception)};

				@{byte[]} result = ::uArray::New(@{byte[]:TypeOf}, (int)length, bytesPtr);
				return result;
			}
			#endif
			return NULL;
		@}
	}
}
