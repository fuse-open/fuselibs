using Uno;
using Uno.Collections;
using Uno.Text;
using Uno.Threading;
using Uno.IO;
using Uno.UX;

namespace Fuse.Scripting.JavaScript
{
	public abstract class JSContext: Fuse.Scripting.Context, IMirror
	{
		readonly Dictionary<ScriptClass, Function> _registeredClasses = new Dictionary<ScriptClass, Function>();
		PropertyHandle _classInstanceProperty = Properties.CreateHandle();
		Function _setSuperclass;
		int _reflectionDepth;

		Fuse.Reactive.FuseJS.Builtins FuseJS { private set; internal get;}

		public sealed override Fuse.Scripting.IThreadWorker ThreadWorker
		{
			get
			{
				return Fuse.Reactive.JavaScript.Worker;
			}
		}

		static JSContext()
		{
			// Make sure all objects have script classes
			ScriptClass.Register(typeof(object));
		}

		protected JSContext() : base () {}

		internal static JSContext Create()
		{
			JSContext result;

			if defined(USE_JAVASCRIPTCORE) result = new Fuse.Scripting.JavaScriptCore.Context();
			else if defined(USE_V8) result = new Fuse.Scripting.V8.Context();
			else if defined(USE_DUKTAPE) result = new Fuse.Scripting.Duktape.Context();
			else throw new Exception("No JavaScript VM available for this platform");

			// The reason for populating FuseJS here and not in the constructor is that if the
			// context is not fully constructed when passed to `new Builtins` a segmentation fault
			// occurs on (at least some) c++ backends
			result.FuseJS = new Fuse.Reactive.FuseJS.Builtins(result);
			return result;
		}

		public sealed override object Wrap(object obj)
		{
			return TypeWrapper.Wrap(this, obj);
		}

		public sealed override object Unwrap(object obj)
		{
			return TypeWrapper.Unwrap(this, obj);
		}

		public sealed override object Reflect(object obj)
		{
			var e = obj as Scripting.External;
			if (e != null) return e.Object;

			var sobj = obj as Scripting.Object;
			if (sobj != null)
			{
				if (sobj.ContainsKey("external_object"))
				{
					var ext = sobj["external_object"] as Scripting.External;
					if (ext != null) return ext.Object;
				}
			}

			object res = null;

			_reflectionDepth++;
			try
			{
				res = CreateMirror(obj);
			}
			finally
			{
				_reflectionDepth--;
			}

			return res;
		}

		object IMirror.Reflect(Scripting.Context context, object obj)
		{
			if (context != this)
				Fuse.Diagnostics.InternalError("IMirror.Reflect with inconsistent context", this);

			return Reflect(obj);
		}

		object CreateMirror(object obj)
		{
			if (_reflectionDepth > 50)
			{
				Diagnostics.UserWarning("JavaScript data model contains circular references or is too deep. Some data may not display correctly.", this);
				return null;
			}

			var a = obj as Scripting.Array;
			if (a != null)
			{
				return new ArrayMirror(this, this, a);
			}

			var f = obj as Scripting.Function;
			if (f != null)
			{
				return new FunctionMirror(f);
			}

			var o = obj as Scripting.Object;
			if (o != null)
			{
				if (o.InstanceOf(this, FuseJS.Observable))
				{
					return new Observable(this, (ThreadWorker)ThreadWorker, o, false);
				}
				else if (o.InstanceOf(this, FuseJS.Date))
				{
					return DateTimeConverterHelpers.ConvertDateToDateTime(this, o);
				}
				else if (o.InstanceOf(this, FuseJS.TreeObservable))
				{
					return new TreeObservable(this, o);
				}
				else
				{
					return new ObjectMirror(this, this, o);
				}
			}

			return obj;
		}

		internal Function GetClass(ScriptClass sc)
		{
			Function cl;
			if (!_registeredClasses.TryGetValue(sc, out cl))
			{
				cl = RegisterClass(sc);
				_registeredClasses.Add(sc, cl);
			}
			return cl;
		}

		Function RegisterClass(ScriptClass sc)
		{
			var cl = (Function)Evaluate(sc.Type.FullName + " (ScriptClass)", "(function(external_object) { this.external_object = external_object; })");

			if (sc.SuperType != null)
			{
				var super = GetClass(sc.SuperType);

				if (_setSuperclass == null)
					_setSuperclass = (Function)Evaluate("(set-superclass)", "(function(cl, superclass) { cl.prototype = new superclass(); cl.prototype.constructor = cl; })");

				_setSuperclass.Call(this, cl, super);
			}

			for (int i = 0; i < sc.Members.Length; i++)
			{
				var inlineMethod = sc.Members[i] as ScriptMethodInline;
				if (inlineMethod != null)
				{
					var m = (Function)Evaluate(sc.Type.FullName + "." + inlineMethod.Name + " (ScriptMethod)", "(function(cl, Observable) { cl.prototype." + inlineMethod.Name + " = " + inlineMethod.Code + "; })");
					m.Call(this, cl, FuseJS.Observable);
					continue;
				}

				var method = sc.Members[i] as ScriptMethod;
				if (method != null)
				{
					new MethodClosure(this, cl, method);
					continue;
				}

				var property = sc.Members[i] as ScriptProperty;
				if (property != null)
				{
					new PropertyClosure(this, cl, property);
					continue;
				}
				var readonlyProperty = sc.Members[i] as ScriptReadonlyProperty;
				if (readonlyProperty != null)
				{
					new ReadonlyPropertyClosure(this, cl, readonlyProperty);
					continue;
				}
			}

			return cl;
		}

		/** Retrieves the ClassInstance associated with the given name scope in this thread worker. */
		internal ClassInstance GetClassInstance(NameTable scope)
		{
			var rootTable = FindRootTable(scope);

			return GetClassInstance(rootTable.This, rootTable);
		}

		/** Retrieves the ClassInstance associated with the given object in this thread worker. */
		internal ClassInstance GetClassInstance(object obj, NameTable rootTable)
		{
			var n = obj as IProperties;
			if (n != null)
			{
				var ni = n.Properties.Get(_classInstanceProperty) as ClassInstance;
				if (ni == null) 
				{
					ni = new ClassInstance((ThreadWorker)ThreadWorker, obj, rootTable);
					n.Properties.Set(_classInstanceProperty, ni);
				}
				return ni;
			}

			throw new Exception("Cannot use object of type '" + rootTable.This.GetType().FullName + "' as 'this' in JavaScript module; must be 'IProperties' or 'App'");
		}

		internal ClassInstance GetExistingClassInstance(IProperties n)
		{
			return n.Properties.Get(_classInstanceProperty) as ClassInstance;
		}

		static NameTable FindRootTable(NameTable names)
		{
			var nt = names;
			while (nt != null)
			{
				if (nt.This != null) return nt;
				nt = nt.ParentTable;
			}
			throw new Exception();
		}

		class ReadonlyPropertyClosure
		{
			public ReadonlyPropertyClosure(Scripting.Context context, Function cl, ScriptReadonlyProperty constant)
			{
				var definer = (Function)context.Evaluate(constant.Name + " (ScriptReadonlyProperty)",
					"(function(cl,propValue)"
					+ "{"
						+ "Object.defineProperty("
							+ "cl.prototype,"
							+ "'" + constant.Name + "',"
							+ "{"
								+ "value: propValue,"
								+ "writable: false,"
								+ "enumerable: true,"
								+ "configurable: false"
							+ "}"
						+ ");"
					+ "})");
				definer.Call(context, cl, context.Unwrap(constant.Value));
			}
		}

		class PropertyClosure
		{
			readonly ScriptProperty _p;

			public PropertyClosure(Scripting.Context context, Function cl, ScriptProperty p)
			{
				_p = p;

				var rawField = "this._raw_" + p.Name;
				var propField = "this._" + p.Name;

				// The backing observable may be recycled between accesses if the associated view
				// is unrooted. This is why we need to call getObservable() time every and check if it has changed.

				var definer = (Function)context.Evaluate(p.Name + " (ScriptProperty)",
						"(function(cl, getObservable) { Object.defineProperty(cl.prototype, '" + p.Name + "', "
							+ "{" 
								+ "get: function() { "
									+ "var obs = getObservable(this); "
									+ "if (" + rawField + " != obs) {"
										+ rawField + " = obs;"
										+ propField + " = obs" + p.Modifier + ";"
									+ "}"
									+ "return " + propField
								+ "}"
							+ "})"
						+ "})");

				definer.Call(context, cl, (Callback)GetObservable);
			}

			object GetObservable(Scripting.Context context, object[] args)
			{
				var obj = context.Wrap(args[0]) as PropertyObject;
				var ci = ((JSContext)context).GetClassInstance(obj, null);
				return ci.GetPropertyObservable(context, _p.GetProperty(obj));
			}
		}

		class MethodClosure
		{
			readonly ScriptMethod _m;
			public MethodClosure(Scripting.Context context, Function cl, ScriptMethod m)
			{
				_m = m;

				var factory = (Function)context.Evaluate(m.Name + " (ScriptMethod)", "(function (cl, callback) { cl.prototype." + m.Name + 
					" = function() { return callback(this.external_object, Array.prototype.slice.call(arguments)); }})");

				factory.Call(context, cl, (Callback)Callback);
			}

			static object[] _emptyArgs = new object[0];

			object Callback(Scripting.Context context, object[] args)
			{
				var self = ((External)args[0]).Object;
				var realArgs = CopyArgs(context, (Scripting.Array)args[1]);
				var res = context.Unwrap(_m.Call(context, self, realArgs));
				return res;
			}

			static object[] CopyArgs(Scripting.Context context, Scripting.Array args)
			{
				var res = new object[args.Length];
				for (int i = 0; i < res.Length; i++) res[i] = context.Wrap(args[i]);
				return res;
			}
		}
	}
}
