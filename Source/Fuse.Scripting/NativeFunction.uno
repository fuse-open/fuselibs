using Uno;
using Uno.Collections;

namespace Fuse.Scripting
{
	public delegate object NativeCallback(Context c, object[] args);

	public sealed class NativeFunction: NativeMember
	{
		NativeCallback _nativeCallback;

		protected override object CreateObject(Context context)
		{
			return (Callback)(new NativeFunctionClosure(_nativeCallback, context).Callback);
		}

		public NativeFunction(string name, NativeCallback callback): base(name)
		{
			_nativeCallback = callback;
		}

		class NativeFunctionClosure
		{
			NativeCallback _callback;
			Context _context;

			public NativeFunctionClosure(NativeCallback callback, Context context)
			{
				_context = context;
				_callback = callback;
			}

			public object Callback(Context context, object[] args)
			{
				return _callback(_context, args);
			}
		}
	}
}
