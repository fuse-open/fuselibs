using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Scripting.JavaScriptCore
{
	[Require("Header.Include", "JavaScriptCore/JavaScript.h")]
	extern(USE_JAVASCRIPTCORE) class Function: Scripting.Function
	{
		readonly Context _context;
		internal readonly JSObjectRef _value;

		internal Function(Context context, JSObjectRef function)
		{
			_context = context;
			_value = function;
			_value.GetJSValueRef().Protect(_context._context);
		}

		~Function()
		{
			if (!_context._disposed)
				_value.GetJSValueRef().Unprotect(_context._context);
		}

		public override object Call(Scripting.Context context, params object[] args)
		{
			// Ensure this function is being called from the context/vm it belongs to
			assert context == _context;

			return _context.Wrap(
				_value.CallAsFunction(
					_context._context,
					default(JSObjectRef),
					_context.Unwrap(args),
					_context._onError));
		}

		public override Scripting.Object Construct(params object[] args)
		{
			return (Scripting.Object)_context.Wrap(
				_value.CallAsConstructor(
					_context._context,
					_context.Unwrap(args),
					_context._onError).GetJSValueRef());
		}

		public override bool Equals(Scripting.Function f)
		{
			return f is Function && _value.Equals(((Function)f)._value);
		}

		public override int GetHashCode()
		{
			return _value.GetHashCode();
		}
	}
}
