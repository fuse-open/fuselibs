using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Scripting.Jurassic
{
	extern(DOTNET)
	public class Array : Fuse.Scripting.Array
	{

		internal ArrayHandle Handle { get { return _handle; } }

		readonly ArrayHandle _handle;
		readonly Context _context;

		internal Array(
			ArrayHandle handle,
			Context context)
		{
			_handle = handle;
			_context = context;
		}

		public override bool Equals(Scripting.Array a)
		{
			var aa = a as Array;
			if (aa == null) return false;
			return _context.Equals(aa._context) && _handle.Equals(aa._handle);
		}

		public override int GetHashCode()
		{
			return _handle.GetHashCode();
		}

		public override object this[int index]
		{
			get
			{
				try
				{
					var obj = ArrayImpl.GetValue(_handle, index);
					var value = JurassicHelpers.FromHandle(_context, obj);
					return value;
				}
				catch(JurassicException je)
				{
					throw je.ToScriptException();
				}
			}
			set
			{
				try
				{
					var handle = JurassicHelpers.ToHandle(_context, value);
					ArrayImpl.SetValue(_handle, index, handle);
				}
				catch(JurassicException je)
				{
					throw je.ToScriptException();
				}
			}
		}

		public override int Length
		{
			get { return ArrayImpl.GetLength(_handle); }
		}
	}

	[DotNetType]
	extern(DOTNET) class ArrayHandle { }

	[DotNetType]
	extern(DOTNET) static class ArrayImpl
	{
		public static extern int GetLength(ArrayHandle handle);

		public static extern void SetValue(ArrayHandle handle, int index, object value);

		public static extern object GetValue(ArrayHandle handle, int index);

	}

}
