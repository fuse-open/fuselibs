using Uno.Compiler.ExportTargetInterop;
using Uno;

namespace Fuse.Scripting.JavaScriptCore
{
	[Require("Header.Include", "JavaScriptCore/JavaScript.h")]
	extern(USE_JAVASCRIPTCORE) class Array: Fuse.Scripting.Array
	{
		readonly Context _context;
		internal readonly JSObjectRef _value;

		internal Array(Context context, JSObjectRef array)
		{
			_context = context;
			_value = array;
			_value.GetJSValueRef().Protect(_context._context);
		}

		~Array()
		{
			if (!_context._disposed)
				_value.GetJSValueRef().Unprotect(_context._context);
		}

		public override object this[int index]
		{
			get
			{
				return _context.Wrap(_value.GetPropertyAtIndex(
					_context._context,
					index,
					_context._onError));
			}
			set
			{
				_value.SetPropertyAtIndex(_context._context,
					index,
					_context.Unwrap(value),
					_context._onError);
			}
		}

		public override int Length
		{ 
			get
			{
				return (int)_value.GetProperty(
					_context._context,
					"length",
					_context._onError).ToNumber(
						_context._context,
						_context._onError);
			}
		}

		public override bool Equals(Scripting.Array a)
		{
			var jsa = (Array)a;
			return _value.Equals(jsa._value);
		}

		public override int GetHashCode()
		{
			return _value.GetHashCode();
		}
	}
}
