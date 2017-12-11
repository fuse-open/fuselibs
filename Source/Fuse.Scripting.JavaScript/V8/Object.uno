using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Scripting.V8
{
	[Require("Header.Include", "include/V8Simple.h")]
	internal extern(USE_V8) class Object: Scripting.Object
	{
		[WeakReference]
		readonly Context _context;
		internal readonly Simple.JSObject _object;

		internal Simple.JSObject GetJSObject(AutoReleasePool pool)
		{
			_object.AsValue().Retain(_context._context);
			return pool.AutoRelease(_object);
		}

		public Object(Context context, Simple.JSObject obj)
		{
			_context = context;
			_object = obj;
			_object.AsValue().Retain(_context._context);
		}

		~Object()
		{
			if (_context != null && !_context.IsDisposed)
				_object.AsValue().Release(_context._context);
		}

		public override object this[string key]
		{
			get
			{
				var cxt = _context._context;
				object result = null;
				using (var pool = new AutoReleasePool(cxt))
				using (var vm = new Context.EnterVM(_context))
					result = Marshaller.Wrap(_context, _object.GetProperty(cxt, key, pool, _context._errorHandler));
				_context.ThrowPendingExceptions();
				return result;
			}
			set
			{
				var cxt = _context._context;
				using (var pool = new AutoReleasePool(cxt))
				using (var vm = new Context.EnterVM(_context))
					_object.SetProperty(cxt, key, Marshaller.Unwrap(_context, value, pool), pool, _context._errorHandler);
				_context.ThrowPendingExceptions();
			}
		}

		public override string[] Keys
		{
			get
			{
				var cxt = _context._context;
				string[] result = null;
				using (var pool = new AutoReleasePool(cxt))
				using (var vm = new Context.EnterVM(_context))
				{
					var keys = _object.GetOwnPropertyNames(cxt, pool, _context._errorHandler);
					int len = keys.Length(cxt);
					result = new string[len];
					for (int i = 0; i < len; ++i)
					{
						var prop = keys.GetProperty(cxt, i, pool, _context._errorHandler);
						var wrappedProp = Marshaller.Wrap(_context, prop);
						var strProp = wrappedProp as string;
						if (strProp == null)
							strProp = wrappedProp.ToString();
						result[i] = strProp;
					}
				}
				_context.ThrowPendingExceptions();
				return result;
			}
		}

		public override bool InstanceOf(Scripting.Context context, Scripting.Function type)
		{
			if (context != _context)
				throw new ArgumentException("Inconsistent context", nameof(context));

			var f = type as Function;
			return (bool)_context._instanceOf.Call(_context, this, type);
		}

		public override bool InstanceOf(Scripting.Function type)
		{
			return InstanceOf(_context, type);
		}

		public override object CallMethod(Scripting.Context context, string name, params object[] args)
		{
			if (context != _context)
				throw new ArgumentException("Inconsistent context", nameof(context));

			var cxt = _context._context;
			object result = null;
			using (var pool = new AutoReleasePool(cxt))
			using (var vm = new Context.EnterVM(_context))
			{
				var fun = Marshaller.Wrap(_context, _object.GetProperty(cxt, name, pool, _context._errorHandler)) as Function;
				if (fun == null)
					throw new Scripting.Error("No such method: " + fun);
				var unwrappedArgs = Marshaller.UnwrapArray(_context, args, pool);
				result = Marshaller.Wrap(_context,
					fun.GetJSFunction(pool).Call(cxt, _object, unwrappedArgs, pool, _context._errorHandler));
			}
			_context.ThrowPendingExceptions();
			return result;
		}

		public override object CallMethod(string name, params object[] args)
		{
			return CallMethod(_context, name, args);
		}

		public override bool ContainsKey(string key)
		{
			var cxt = _context._context;
			bool result = false;
			using (var pool = new AutoReleasePool(cxt))
			using (var vm = new Context.EnterVM(_context))
				result = _object.HasProperty(cxt, key, pool, _context._errorHandler);
			_context.ThrowPendingExceptions();
			return result;
		}

		public override bool Equals(Scripting.Object o)
		{
			var that = o as Object;
			return that != null && _object.Equals(that._object);
		}

		public override int GetHashCode()
		{
			return _object.GetHashCode();
		}
	}
}
