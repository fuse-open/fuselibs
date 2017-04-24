using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Scripting.Duktape
{
	extern(USE_DUKTAPE) class Array : Fuse.Scripting.Array
	{
		internal readonly IntPtr _handle;
		readonly Context _ctx;
		readonly int _stashKey;

		public Array(Context ctx, IntPtr handle)
		{
			_ctx = ctx;
			_handle = handle;
			_stashKey = _ctx.Stash(_handle);
		}

		~Array()
		{
			_ctx._unstash.Enqueue(_stashKey);
		}

		public override int Length
		{
			get
			{
				var index = _ctx.DukContext.push_heapptr(_handle);
				var l = _ctx.DukContext.get_length(index);
				_ctx.DukContext.pop();
				return (int)l;
			}
		}

		public override object this[int index]
		{
			get
			{
				var objIndex = _ctx.DukContext.push_heapptr(_handle);
				_ctx.DukContext.get_prop_index(objIndex, index);
				var res = _ctx.IndexToObject(-1);
				_ctx.DukContext.pop_2();
				return res;
			}
			set
			{
				var objIndex = _ctx.DukContext.push_heapptr(_handle);
				_ctx.Push(value);
				_ctx.DukContext.put_prop_index(objIndex, index);
				_ctx.DukContext.pop();
			}
		}

		public override bool Equals(Fuse.Scripting.Array a)
		{
			var ja = a as Array;
			return ja != null && _ctx == ja._ctx && _handle == ja._handle;
		}

		public override int GetHashCode()
		{
			return _handle.GetHashCode();
		}
	}
}
