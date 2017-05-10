using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Scripting.Jurassic
{
	extern(DOTNET)
	public class Function : Fuse.Scripting.Function
	{
		internal FunctionHandle Handle { get { return _handle; } }

		readonly FunctionHandle _handle;
		readonly Context _context;

		internal Function(
			FunctionHandle handle,
			Context context)
		{
			_handle = handle;
			_context = context;
		}

		public override Scripting.Object Construct(params object[] args)
		{
			try
			{
				var arguments = JurassicHelpers.ToHandles(_context, args);
				var result = FunctionImpl.Construct(_handle, arguments);
				return (Object)JurassicHelpers.FromHandle(_context, result);
			}
			catch(JurassicException je)
			{
				throw je.ToScriptException();
			}
		}

		public override object Call(params object[] args)
		{
			try
			{
				var arguments = JurassicHelpers.ToHandles(_context, args);
				var result = FunctionImpl.Call(_handle, arguments);
				return JurassicHelpers.FromHandle(_context, result);
			}
			catch(JurassicException je)
			{
				throw je.ToScriptException();
			}
		}

		public override bool Equals(Scripting.Function a)
		{
			var aa = a as Function;
			if (aa == null) return false;
			return _context.Equals(aa._context) && _handle.Equals(aa._handle);
		}

		public override int GetHashCode()
		{
			return _handle.GetHashCode();
		}
	}

	extern(DOTNET) class ScriptCallback
	{
		readonly Fuse.Scripting.Callback _callback;
		readonly Context _context;

		public ScriptCallback(Fuse.Scripting.Callback callback, Context context)
		{
			_callback = callback;
			_context = context;
		}

		public object Invoke(object[] args)
		{
			try
			{
				var arguments = JurassicHelpers.FromHandles(_context, args);
				var result = _callback(arguments);
				return JurassicHelpers.ToHandle(_context, result);
			}
			catch (Scripting.Error e)
			{
				ContextImpl.ThrowJavaScriptException(_context.Handle, e.Message);
				return null;
			}
		}
	}

    [DotNetType]
	extern(DOTNET) class FunctionHandle { }

    [DotNetType]
	extern(DOTNET) static class FunctionImpl
	{
		public static extern FunctionHandle FromScriptCallback(ContextHandle contextHandle, Func<object[], object> callback);

		public static extern object Call(FunctionHandle handle, params object[] args);

		public static extern object Construct(FunctionHandle handle, params object[] args);
	}


}
