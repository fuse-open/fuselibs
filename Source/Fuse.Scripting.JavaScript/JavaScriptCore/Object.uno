using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Uno;

namespace Fuse.Scripting.JavaScriptCore
{
	[Require("Header.Include", "JavaScriptCore/JavaScript.h")]
	extern(USE_JAVASCRIPTCORE) class Object: Scripting.Object
	{
		readonly Context _context;
		internal readonly JSObjectRef _value;

		internal Object(Context context, JSObjectRef value)
		{
			_context = context;
			_value = value;
			_value.GetJSValueRef().Protect(_context._context);
		}

		~Object()
		{
			if (!_context._disposed)
				_value.GetJSValueRef().Unprotect(_context._context);
		}

		public override object this[string key]
		{
			get
			{
				return _context.Wrap(_value.GetProperty(
					_context._context,
					key,
					_context._onError));
			}
			set
			{
				_value.SetProperty(
					_context._context,
					key,
					_context.Unwrap(value),
					_context._onError);
			}
		}

		public override string[] Keys
		{
			get
			{
				using (var arr = _value.CopyPropertyNames(_context._context))
				{
					var count = arr.GetCount();
					var result = new string[count];
					for (int i = 0; i < count; ++i)
					{
						result[i] = arr[i].ToString();
					}
					return result;
				}
			}
		}

		public override bool InstanceOf(Scripting.Function type)
		{
			return type is Function
				&& _value.GetJSValueRef().IsInstanceOfConstructor(
					_context._context,
					((Function)type)._value,
					_context._onError);
		}

		public override object CallMethod(Scripting.Context context, string name, params object[] args)
		{
			var ctx = (Context)context;
			if (name == null) throw new ArgumentException("Object.CallMethod.name");
			var f = _value.GetProperty(
				ctx._context,
				name,
				ctx._onError).GetJSObjectRef(ctx._context);
			return ctx.Wrap(
				f.CallAsFunction(
					ctx._context,
					_value,
					ctx.Unwrap(args),
					ctx._onError));
		}

		public override bool ContainsKey(string key)
		{
			return _value.HasProperty(_context._context, key);
		}

		public override bool Equals(Scripting.Object o)
		{
			return o is Object && _value.Equals(((Object)o)._value);
		}

		public override int GetHashCode()
		{
			return _value.GetHashCode();
		}
	}
}
