using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Scripting.Duktape
{
	extern(USE_DUKTAPE) class Function : Fuse.Scripting.Function
	{
		internal readonly IntPtr _handle;
		readonly Context _ctx;
		readonly int _stashKey;

		internal Function(Context ctx, IntPtr handle)
		{
			_ctx = ctx;
			_handle = handle;
			_stashKey = _ctx.Stash(_handle);
		}

		~Function()
		{
			_ctx._unstash.Enqueue(_stashKey);
		}

		public override bool Equals(Fuse.Scripting.Function a)
		{
			var f = a as Function;
			return f != null && _ctx == f._ctx && _handle == f._handle;
		}

		public override int GetHashCode()
		{
			return _handle.GetHashCode();
		}

		public override Fuse.Scripting.Object Construct(Scripting.Context context, params object[] args)
		{
			if (context != _ctx)
				throw new ArgumentException("Inconsistent context", nameof(context));

			_ctx.DukContext.push_heapptr(_handle);
			var argc = args.Length;
			for (int i = 0; i < argc; i++)
			{
				_ctx.Push(args[i]);
			}
			_ctx.DukContext.new_(argc);
			var returnValue = _ctx.IndexToObject(-1);
			_ctx.DukContext.pop();
			return (Object)returnValue;
		}

		public override Fuse.Scripting.Object Construct(params object[] args)
		{
			return Construct(_ctx, args);
		}

		public override object Call(Scripting.Context context, params object[] args)
		{
			if (context != _ctx)
				throw new ArgumentException("Inconsistent context", nameof(context));

			_ctx.DukContext.push_heapptr(_handle);

			var argc = args.Length;
			for (int i = 0; i < argc; i++)
			{
				_ctx.Push(args[i]);
			}

			_ctx.CheckError(_ctx.DukContext.pcall(argc));

			var returnValue = _ctx.IndexToObject(-1);
			_ctx.DukContext.pop();
			return returnValue;
		}

		public override object Call(params object[] args)
		{
			return Call(_ctx, args);
		}
	}
}
