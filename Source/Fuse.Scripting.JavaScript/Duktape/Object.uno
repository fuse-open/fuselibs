using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Scripting.Duktape
{
	extern(USE_DUKTAPE) class Object : Fuse.Scripting.Object
	{
		internal readonly IntPtr _handle;
		readonly Context _ctx;
		readonly int _stashKey;

		public Object(Context ctx, IntPtr handle)
		{
			_ctx = ctx;
			_handle = handle;
			_stashKey = _ctx.Stash(_handle);
		}

		~Object()
		{
			_ctx._unstash.Enqueue(_stashKey);
		}

		public override bool Equals(Fuse.Scripting.Object obj)
		{
			var o = obj as Object;
			return o != null && _ctx == o._ctx && _handle == o._handle;
		}

		public override int GetHashCode()
		{
			return _handle.GetHashCode();
		}

		public override bool InstanceOf(Scripting.Context context, Fuse.Scripting.Function type)
		{
			if (context != _ctx)
				throw new ArgumentException("Inconsistent context", nameof(context));

			var func = type as Function;
			if (func == null) return false;
			var objIndex = _ctx.DukContext.push_heapptr(_handle);
			var typeIndex = _ctx.DukContext.push_heapptr(func._handle);
			var result = _ctx.DukContext.instanceof(objIndex, typeIndex);
			_ctx.DukContext.pop_2();
			return result;
		}

		public override bool InstanceOf(Fuse.Scripting.Function type)
		{
			return InstanceOf(_ctx, type);
		}

		public override object this[string key]
		{
			get
			{
				if (key == null) throw new ArgumentNullException(nameof(key));
				var objIndex = _ctx.DukContext.push_heapptr(_handle);
				_ctx.DukContext.get_prop_string(objIndex, key);
				var res = _ctx.IndexToObject(-1);
				_ctx.DukContext.pop_2();
				return res;
			}

			set
			{
				if (key == null) throw new ArgumentNullException(nameof(key));
				var objIndex = _ctx.DukContext.push_heapptr(_handle);
				_ctx.Push(value);
				_ctx.DukContext.put_prop_string(objIndex, key);
				_ctx.DukContext.pop();
			}
		}

		public override string[] Keys
		{
			get
			{
				var keys = new List<string>();
				var index = _ctx.DukContext.push_heapptr(_handle);

				_ctx.DukContext.enum_own_properties(index);

				while (_ctx.DukContext.next(-1, false))
				{
					var key = _ctx.DukContext.get_string(-1);
					keys.Add(key);
					_ctx.DukContext.pop();
				}

				_ctx.DukContext.pop_2();

				return keys.ToArray();
			}
		}

		public override object CallMethod(Scripting.Context context, string name, params object[] args)
		{
			if (context != _ctx)
				throw new ArgumentException("Inconsistent context", nameof(context));

			if (name == null)
				throw new ArgumentNullException(nameof(name));

			var index = _ctx.DukContext.push_heapptr(_handle);

			_ctx.DukContext.get_prop_string(index, name);
			_ctx.DukContext.push_heapptr(_handle);

			for (int i = 0; i < args.Length; i++)
				_ctx.Push(args[i]);

			_ctx.CheckError(_ctx.DukContext.pcall_method(args.Length));

			var returnVal = _ctx.IndexToObject(-1);
			_ctx.DukContext.pop_2();

			return returnVal;
		}

		public override object CallMethod(string name, params object[] args)
		{
			return CallMethod(_ctx, name, args);
		}

		public override bool ContainsKey(string key)
		{
			if (key == null) throw new ArgumentNullException(nameof(key));
			var index = _ctx.DukContext.push_heapptr(_handle);
			var result = _ctx.DukContext.has_prop_string(index, key);
			_ctx.DukContext.pop();
			return result;
		}

	}
}
