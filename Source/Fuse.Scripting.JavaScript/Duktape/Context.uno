using Uno;
using Uno.UX;
using Uno.Collections;
using Uno.Threading;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Scripting.Duktape
{
	extern(USE_DUKTAPE) class RawCallback
	{
		Context _context;
		Callback _callback;

		public RawCallback(Context context, Callback callback)
		{
			_context = context;
			_callback = callback;
		}

		public void Call(IntPtr argsPtr)
		{
			try
			{
				var jsArgs = new Array(_context, argsPtr);
				int len = jsArgs.Length;
				object[] args = new object[len];
				for (int i = 0; i < len; ++i)
				{
					args[i] = jsArgs[i];
				}
				_context.Push(_callback(_context, args));
			}
			catch (Scripting.Error e)
			{
				_context.DukContext.error(e.Message);
			}
		}
	}

	public extern(USE_DUKTAPE) class Context : Fuse.Scripting.JavaScript.JSContext
	{
		readonly Object _globalObject;
		internal readonly ConcurrentQueue<int> _unstash = new ConcurrentQueue<int>();
		internal readonly Function _externalType;
		readonly Function _arrayBufferType;
		readonly Function _callbackFactory;
		internal readonly duk_context DukContext;

		public override Fuse.Scripting.Object GlobalObject { get { return _globalObject; } }

		public Context(): base()
		{
			DukContext = duktape.create_heap_default();

			{
				DukContext.push_global_object();
				_globalObject = (Object)IndexToObject(-1);
				DukContext.pop();
			}

			_externalType = (Function)Evaluate(
				"(no file)",
				"(function External(ptr) { this.Object = ptr; })");
			_arrayBufferType = _globalObject["ArrayBuffer"] as Function;
			{
				var callbackFactoryFactory = (Function)Evaluate(
					"(no file)",
					"(function(proxy) { return function(ext) { return function() { return proxy(ext, arguments); }; }; })");
				DukContext.push_callback_proxy();
				var proxy = IndexToObject(-1);
				DukContext.pop();
				_callbackFactory = (Function)callbackFactoryFactory.Call(proxy);
			}
		}

		~Context()
		{
			Dispose();
		}

		public override void Dispose()
		{
			duktape.destroy_heap(DukContext);
		}

		public override object Evaluate(string fileName, string code)
		{
			Push(code);
			Push(fileName);

			CheckError(DukContext.pcompile(0u));
			CheckError(DukContext.pcall(0));

			var result = IndexToObject(-1);
			DukContext.pop();
			return result;
		}

		void PushExternal(object o)
		{
			DukContext.push_heapptr(_externalType._handle);
			DukContext.push_external_buffer();
			DukContext.config_buffer(-1, extern<IntPtr> "$0", 0);

			@{
				uRetain($0);
			@}

			DukContext.new_(1);
			DukContext.push_external_finalizer();
			DukContext.set_finalizer(-2);
		}

		object GetExternalObject(Object wrapper)
		{
			DukContext.push_heapptr(wrapper._handle);
			DukContext.get_prop_string(-1, "Object");
			int size;
			var result = extern<object>(DukContext.get_buffer(-1, out size)) "(@{object})$0";
			DukContext.pop_2();
			return result;
		}

		void PushArrayBuffer(byte[] data)
		{
			DukContext.push_external_buffer();
			DukContext.config_buffer(-1, extern<IntPtr> "$0->Ptr()", data.Length);
			DukContext.push_array_buffer(-1, 0, data.Length);
			PushExternal(data);
			DukContext.put_prop_string(-2, "__unoHandle");
			var result = DukContext.get_heapptr(-1);
			var stashKey = Stash(result);
			DukContext.pop_2();
			_unstash.Enqueue(stashKey);
			DukContext.push_heapptr(result);
		}

		byte[] GetArrayBufferData(Object o)
		{
			if (o.ContainsKey("__unoHandle"))
			{
				var ext = o["__unoHandle"] as External;
				if (ext != null)
				{
					var arr = ext.Object as byte[];
					if (arr != null)
					{
						return arr;
					}
				}
			}
			DukContext.push_heapptr(o._handle);
			int length;
			var ptr = DukContext.get_buffer_data(-1, out length);
			if (ptr == IntPtr.Zero)
			{
				throw new Exception("Duktape: Unable to get data from ArrayBuffer");
			}
			DukContext.pop();
			return extern<byte[]> (length, ptr) "uArray::New(@{byte[]:TypeOf}, $0, $1)";
		}

		internal object IndexToObject(int index)
		{
			if (DukContext.is_null_or_undefined(index)) return null;
			if (DukContext.is_number(index)) return DukContext.get_number(index);
			if (DukContext.is_string(index)) return DukContext.get_string(index);
			if (DukContext.is_boolean(index)) return DukContext.get_boolean(index);
			if (DukContext.is_function(index)) return new Function(this, DukContext.get_heapptr(index));
			if (DukContext.is_array(index)) return new Array(this, DukContext.get_heapptr(index));
			if (DukContext.is_object(index))
			{
				var obj = new Object(this, DukContext.get_heapptr(index));
				if (obj.InstanceOf(_arrayBufferType)) return GetArrayBufferData(obj);
				if (obj.InstanceOf(_externalType)) return new External(GetExternalObject(obj));
				return obj;
			}
			throw new Exception("Could not convert index to object");
		}

		internal void Push(object value)
		{
			if (value == null) { DukContext.push_null(); return; }
			if (value is int) { DukContext.push_int((int)value); return; }
			if (value is double) { DukContext.push_number((double)value); return; }
			if (value is float) { DukContext.push_number((float)value); return; }
			if (value is string) { DukContext.push_string((string)value); return; }
			if (value is Selector) { DukContext.push_string((string)(Selector)value); return; }
			if (value is bool) { DukContext.push_boolean((bool)value); return; }
			if (value is byte[]) { PushArrayBuffer((byte[])value); return; }

			var c = value as Callback;
			if (c != null)
			{
				Push(_callbackFactory.Call(new External(new Action<IntPtr>(new RawCallback(this, c).Call))));
				return;
			}

			var f = value as Function;
			if (f != null)
			{
				DukContext.push_heapptr(f._handle);
				return;
			}

			var a = value as Array;
			if (a != null)
			{
				DukContext.push_heapptr(a._handle);
				return;
			}

			var o = value as Object;
			if (o != null)
			{
				DukContext.push_heapptr(o._handle);
				return;
			}

			var e = value as External;
			if (e != null)
			{
				PushExternal(e.Object);
				return;
			}

			throw new Exception("Cannot push value: " + value);
		}

		int _stashKey = 0;
		internal int Stash(IntPtr heapPtr)
		{
			DukContext.push_global_stash();
			DukContext.push_heapptr(heapPtr);
			DukContext.put_prop_index(-2, _stashKey);
			DukContext.pop();
			return _stashKey++;
		}

		internal ScriptException GetError(int index)
		{
			string name = null;
			string message = null;
			string fileName = null;
			int lineNumber = -1;
			string stack = null;
			if (DukContext.is_object(index))
			{
				DukContext.get_prop_string(index, "name");
				if (DukContext.is_string(-1))
				{
					name = DukContext.get_string(-1);
				}
				DukContext.pop();

				DukContext.get_prop_string(index, "message");
				if (DukContext.is_string(-1))
				{
					message = DukContext.get_string(-1);
				}
				DukContext.pop();

				DukContext.get_prop_string(index, "fileName");
				if (DukContext.is_string(-1))
				{
					fileName = DukContext.get_string(-1);
				}
				DukContext.pop();

				DukContext.get_prop_string(index, "lineNumber");
				lineNumber = DukContext.get_int(-1);
				DukContext.pop();

				DukContext.get_prop_string(index, "stack");
				if (DukContext.is_string(-1))
				{
					stack = DukContext.get_string(-1);
				}
				DukContext.pop();
			}
			else
			{
				message = DukContext.safe_to_string(index);
			}
			return new ScriptException(name, message, fileName, lineNumber, stack);
		}

		internal void CheckError(int errorCode)
		{
			if (errorCode != 0)
			{
				var e = GetError(-1);
				DukContext.pop();
				throw e;
			}
			// We unstash objects here since it's done periodically and on the correct thread
			if (_unstash.Count > 0)
			{
				DukContext.push_global_stash();
				int stashKey;
				while (_unstash.TryDequeue(out stashKey))
				{
					DukContext.del_prop_index(-1, stashKey);
				}
				DukContext.pop();
			}
		}
	}
}
