using Uno.Compiler.ExportTargetInterop;
using Uno;

namespace Fuse.Scripting.V8
{
	[Require("Header.Include", "include/V8Simple.h")]
	internal extern(USE_V8) class Array: Fuse.Scripting.Array
	{
		[WeakReference]
		readonly Context _context;
		readonly Simple.JSArray _array;

		internal Simple.JSArray GetJSArray(AutoReleasePool pool)
		{
			_array.AsValue().Retain(_context._context);
			return pool.AutoRelease(_array);
		}

		public Array(Context context, Simple.JSArray array)
		{
			_context = context;
			_array = array;
			_array.AsValue().Retain(_context._context);
		}

		~Array()
		{
			if (_context != null && !_context.IsDisposed)
				_array.AsValue().Release(_context._context);
		}

		public override object this[int index]
		{
			get
			{
				var cxt = _context._context;
				object result = null;
				using (var pool = new AutoReleasePool(cxt))
				using (var vm = new Context.EnterVM(_context))
					result = Marshaller.Wrap(_context, _array.GetProperty(cxt, index, pool, _context._errorHandler));
				_context.ThrowPendingExceptions();
				return result;
			}
			set
			{
				var cxt = _context._context;
				using (var pool = new AutoReleasePool(cxt))
				using (var vm = new Context.EnterVM(_context))
					_array.SetProperty(cxt, index, Marshaller.Unwrap(_context, value, pool), _context._errorHandler);
				_context.ThrowPendingExceptions();
			}
		}

		public override int Length
		{
			get
			{
				int result = 0;
				using (var vm = new Context.EnterVM(_context))
					result = _array.Length(_context._context);
				_context.ThrowPendingExceptions();
				return result;
			}
		}

		public override bool Equals(Scripting.Array a)
		{
			var that = a as Array;
			return that != null && _array.Equals(that._array);
		}

		public override int GetHashCode()
		{
			return _array.GetHashCode();
		}
	}
}
