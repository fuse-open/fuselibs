using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Scripting.Jurassic
{
	extern(DOTNET)
	public class Object : Fuse.Scripting.Object
	{
		internal ObjectHandle Handle { get { return _handle; } }

		readonly ObjectHandle _handle;
		readonly Context _context;

		internal Object(
			ObjectHandle handle,
			Context context)
		{
			_handle = handle;
			_context = context;
		}

		public override bool InstanceOf(Scripting.Function obj)
		{
			return ObjectImpl.InstanceOf(_handle, JurassicHelpers.ToHandle(_context, obj));
		}

		public override bool Equals(Scripting.Object a)
		{
			var aa = a as Object;
			if (aa == null) return false;
			return _context.Equals(aa._context) && _handle.Equals(aa._handle);
		}

		public override int GetHashCode()
		{
			return _handle.GetHashCode();
		}

		public override object this[string key]
		{
			get
			{
				try
				{
					var obj = ObjectImpl.GetValue(_handle, key);
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
					ObjectImpl.SetValue(_handle, key, handle);
				}
				catch(JurassicException je)
				{
					throw je.ToScriptException();
				}
			}
		}

		public override string[] Keys
		{
			get
			{
				return ObjectImpl.GetKeys(_handle);
			}
		}

		public override object CallMethod(string name, object[] args)
		{
			try
			{
				var arguments = JurassicHelpers.ToHandles(_context, args);
				var handle = ObjectImpl.CallMethod(_handle, name, arguments);
				return JurassicHelpers.FromHandle(_context, handle);
			}
			catch(JurassicException je)
			{
				throw je.ToScriptException();
			}
		}

		public override bool ContainsKey(string key)
		{
			return ObjectImpl.ContainsKey(_handle, key);
		}

	}

	[DotNetType]
	extern(DOTNET) class ObjectHandle
	{

	}

	[DotNetType]
	extern(DOTNET) static class ObjectImpl
	{
		public static extern void SetValue(ObjectHandle handle, string key, object value);

		public static extern object GetValue(ObjectHandle handle, string key);

		public static extern string[] GetKeys(ObjectHandle handle);

		public static extern bool InstanceOf(ObjectHandle handle, object type);

		public static extern object CallMethod(ObjectHandle handle, string name, object[] args);

		public static extern bool ContainsKey(ObjectHandle handle, string key);

	}

}
