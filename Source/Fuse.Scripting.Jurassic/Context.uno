using Uno;
using Uno.Collections;
using Uno.Threading;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Scripting.Jurassic
{
	[DotNetType("Fuse.Scripting.Jurassic.JurassicException")]
	extern(DOTNET)
	public class JurassicException : Uno.Exception
	{
		public readonly int LineNumber;
		public readonly string Name;
		public readonly string SourcePath;
		public readonly string FunctionName;
		public readonly string ErrorMessage;
		public readonly string StackTrace;
	}

	extern(DOTNET)
	public class Context : Fuse.Scripting.Context
	{
		internal ContextHandle Handle { get { return _handle; } }

		readonly ContextHandle _handle;

		public Context(IThreadWorker worker) : this(ContextImpl.Create(), worker) { }

		internal Context(ContextHandle handle, IThreadWorker worker) : base(worker)
		{
			_handle = handle;
		}

		public override object Evaluate(string fileName, string code)
		{
			try
			{
				var result = ContextImpl.Evaluate(_handle, fileName, code);
				return JurassicHelpers.FromHandle(this, result);
			}
			catch(JurassicException je)
			{
				throw je.ToScriptException();
			}
		}

		public override Fuse.Scripting.Object GlobalObject
		{
			get { return new Object(ContextImpl.GetGlobalObject(_handle), this); }
		}

		public override void Dispose()
		{
			ContextImpl.Dispose(_handle);
		}
	}

    [DotNetType]
	extern(DOTNET) class ContextHandle
	{
	}

	extern(DOTNET) static class ExceptionExtensions
	{
		public static Fuse.Scripting.ScriptException ToScriptException(this JurassicException je)
		{
			return new Fuse.Scripting.ScriptException(
				je.Name,
				je.ErrorMessage,
				je.SourcePath,
				je.LineNumber,
				null,
				(je.StackTrace == "N/A") ? null : je.StackTrace);
		}
	}

    [DotNetType]
	extern(DOTNET) static class ContextImpl
	{
		public static extern ContextHandle Create();

		public static extern ObjectHandle MakeObject(ContextHandle handle);

		public static extern ArrayHandle MakeArray(ContextHandle handle);

		public static extern object Evaluate(ContextHandle handle, string code);

		public static extern object Evaluate(ContextHandle handle, string name, string code);

		public static extern ObjectHandle GetGlobalObject(ContextHandle handle);

		public static extern void Dispose(ContextHandle handle);

		public static extern void ThrowJavaScriptException(ContextHandle handle, string message);

	}

	extern(DOTNET) static class JurassicHelpers
	{
		public static object[] ToHandles(Context ctx, object[] objs)
		{
			var handles = new object[objs.Length];
			for (int i = 0; i < objs.Length; i++)
			{
				handles[i] = ToHandle(ctx, objs[i]);
			}
			return handles;
		}

		public static object[] FromHandles(Context ctx, object[] handles)
		{
			var objs = new object[handles.Length];
			for (int i = 0; i < handles.Length; i++)
			{
				objs[i] = FromHandle(ctx, handles[i]);
			}
			return objs;
		}

		public static object ToHandle(Context ctx, object value)
		{
			if (value is Fuse.Scripting.Callback)
			{
				var scriptCallback = new ScriptCallback((Fuse.Scripting.Callback)value, ctx);
				return FunctionImpl.FromScriptCallback(ctx.Handle, scriptCallback.Invoke);
			}

			if (value is Array)
				return ((Array)value).Handle;

			if (value is Function)
				return ((Function)value).Handle;

			if (value is Object)
				return ((Object)value).Handle;

			if (value is Context)
				return ((Context)value).Handle;

			return value;
		}

		public static object FromHandle(Context ctx, object value)
		{
			if (value is FunctionHandle)
				return new Function((FunctionHandle)value, ctx);

			if (value is ArrayHandle)
				return new Array((ArrayHandle)value, ctx);

			if (value is ObjectHandle)
				return new Object((ObjectHandle)value, ctx);

			if (value is ContextHandle)
				return new Context((ContextHandle)value, ctx.ThreadWorker);

			return value;
		}
	}

}
