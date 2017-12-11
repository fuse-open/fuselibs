using Uno.Compiler.ExportTargetInterop;
using Uno;

namespace Fuse.Scripting.V8
{
	[Require("Header.Include", "include/V8Simple.h")]
	internal extern(USE_V8) class Function: Scripting.Function
	{
		[WeakReference]
		readonly Context _context;
		readonly Simple.JSFunction _function;

		internal Simple.JSFunction GetJSFunction(AutoReleasePool pool)
		{
			_function.AsValue().Retain(_context._context);
			return pool.AutoRelease(_function);
		}

		internal Function(Context context, Simple.JSFunction function)
		{
			_context = context;
			_function = function;
			_function.AsValue().Retain(_context._context);
		}

		~Function()
		{
			if (_context != null && !_context.IsDisposed)
				_function.AsValue().Release(_context._context);
		}

		public override object Call(Scripting.Context context, params object[] args)
		{
			if (context != _context)
				throw new ArgumentException("Inconsistent context", nameof(context));

			var cxt = _context._context;
			object result = null;
			using (var pool = new AutoReleasePool(cxt))
			using (var vm = new Context.EnterVM(_context))
			{
				var unwrappedArgs = Marshaller.UnwrapArray(_context, args, pool);
				var thisObject = V8SimpleExtensions.Null().AsObject();
				result = Marshaller.Wrap(_context,
					_function.Call(
						cxt,
						thisObject,
						unwrappedArgs,
						pool,
						_context._errorHandler));

			}
			_context.ThrowPendingExceptions();
			return result;
		}

		public override object Call(params object[] args)
		{
			return Call(_context, args);
		}

		public override Scripting.Object Construct(Scripting.Context context, params object[] args)
		{
			if (context != _context)
				throw new ArgumentException("Inconsistent context", nameof(context));

			var cxt = _context._context;
			Object result = null;
			using (var pool = new AutoReleasePool(cxt))
			using (var vm = new Context.EnterVM(_context))
			{
				var unwrappedArgs = Marshaller.UnwrapArray(_context, args, pool);
				result = new Object(_context,
					_function.Construct(
						cxt,
						unwrappedArgs,
						pool,
						_context._errorHandler));
			}
			_context.ThrowPendingExceptions();
			return result;
		}

		public override Scripting.Object Construct(params object[] args)
		{
			return Construct(_context, args);
		}

		public override bool Equals(Scripting.Function f)
		{
			var that = f as Function;
			return that != null && _function.Equals(that._function);
		}

		public override int GetHashCode()
		{
			return _function.GetHashCode();
		}
	}
}
