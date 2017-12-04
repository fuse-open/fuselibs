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
				_value.GetJSValueRef().DeferedUnprotect();
		}

		public override object this[int index]
		{
			get
			{
				object result = null;
				using (var vm = new Context.EnterVM(_context))
					result = _context.Wrap(_value.GetPropertyAtIndex(
						_context._context,
						index,
						_context._onError));
				_context.ThrowPendingException();
				return result;
			}
			set
			{
				using (var vm = new Context.EnterVM(_context))
					_value.SetPropertyAtIndex(_context._context,
						index,
						_context.Unwrap(value),
						_context._onError);
				_context.ThrowPendingException();
			}
		}

		public override int Length
		{ 
			get
			{
				int result = 0;
				using (var vm = new Context.EnterVM(_context))
					result = (int)_value.GetProperty(
						_context._context,
						"length",
						_context._onError).ToNumber(
							_context._context,
							_context._onError);
				_context.ThrowPendingException();
				return result;
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
