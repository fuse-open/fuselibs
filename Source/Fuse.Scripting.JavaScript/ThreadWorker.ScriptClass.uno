using Uno;
using Uno.UX;
using Uno.Collections;
using Fuse.Scripting;

namespace Fuse.Scripting.JavaScript
{
	partial class ThreadWorker
	{
		static ThreadWorker()
		{
			// Make sure all objects have script classes
			ScriptClass.Register(typeof(object));
		}
		
		object WrapScriptClass(object obj)
		{
			var so = obj as IScriptObject;
			if (so != null && so.ScriptObject != null) return so.ScriptObject;

			var ext = new External(obj);

			var sc = ScriptClass.Get(obj.GetType());
			if (sc == null) return ext;

			var ctor = GetClass(sc);
			var res = ctor.Construct(ext);

			if (so != null) so.SetScriptObject(res, Context);
			return res;
		}

		readonly Dictionary<ScriptClass, Function> _registeredClasses = new Dictionary<ScriptClass, Function>();

		Function _setSuperclass;

		Function GetClass(ScriptClass sc)
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
			var cl = (Function)Context.Evaluate(sc.Type.FullName + " (ScriptClass)", "(function(external_object) { this.external_object = external_object; })");

			if (sc.SuperType != null)
			{
				var super = GetClass(sc.SuperType);

				if (_setSuperclass == null)
					_setSuperclass = (Function)Context.Evaluate("(set-superclass)", "(function(cl, superclass) { cl.prototype = new superclass(); cl.prototype.constructor = cl; })");

				_setSuperclass.Call(cl, super);
			}

			for (int i = 0; i < sc.Members.Length; i++)
			{
				var inlineMethod = sc.Members[i] as ScriptMethodInline;
				if (inlineMethod != null)
				{
					var m = (Function)Context.Evaluate(sc.Type.FullName + "." + inlineMethod.Name + " (ScriptMethod)", "(function(cl, Observable) { cl.prototype." + inlineMethod.Name + " = " + inlineMethod.Code + "; })");
					m.Call(cl, Observable);
					continue;
				}

				var method = sc.Members[i] as ScriptMethod;
				if (method != null)
				{
					new MethodClosure(cl, method, this);
					continue;
				}

				var property = sc.Members[i] as ScriptProperty;
				if (property != null)
				{
					new PropertyClosure(cl, property, this);
					continue;
				}
				var readonlyProperty = sc.Members[i] as ScriptReadonlyProperty;
				if (readonlyProperty != null)
				{
					new ReadonlyPropertyClosure(cl, readonlyProperty, this);
					continue;
				}
			}

			return cl;
		}

		class ReadonlyPropertyClosure
		{
			public ReadonlyPropertyClosure(Function cl, ScriptReadonlyProperty constant, ThreadWorker worker)
			{
				var definer = (Function)worker.Context.Evaluate(constant.Name + " (ScriptReadonlyProperty)",
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
				definer.Call(cl, worker.Unwrap(constant.Value));
			}
		}

		class PropertyClosure
		{
			readonly ThreadWorker _worker;
			readonly ScriptProperty _p;

			public PropertyClosure(Function cl, ScriptProperty p, ThreadWorker worker)
			{
				_worker = worker;
				_p = p;

				var rawField = "this._raw_" + p.Name;
				var propField = "this._" + p.Name;

				// The backing observable may be recycled between accesses if the associated view
				// is unrooted. This is why we need to call getObservable() every time and check if it has changed.

				var definer = (Function)worker.Context.Evaluate(p.Name + " (ScriptProperty)",
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

				definer.Call(cl, (Callback)GetObservable);
			}

			object GetObservable(Scripting.Context context, object[] args)
			{
				var obj = ThreadWorker.Wrap(args[0]) as PropertyObject;
				var ci = _worker.GetClassInstance(obj, null);
				return ci.GetPropertyObservable(context, _p.GetProperty(obj));
			}
		}

		class MethodClosure
		{
			readonly ScriptMethod _m;
			readonly ThreadWorker _worker;
			public MethodClosure(Function cl, ScriptMethod m, ThreadWorker worker)
			{
				_m = m;
				_worker = worker;

				var factory = (Function)_worker.Context.Evaluate(m.Name + " (ScriptMethod)", "(function (cl, callback) { cl.prototype." + m.Name + 
					" = function() { return callback(this.external_object, Array.prototype.slice.call(arguments)); }})");
				
				factory.Call(cl, (Callback)Callback);	
			}

			static object[] _emptyArgs = new object[0];

			object Callback(Scripting.Context context, object[] args)
			{
				var self = ((External)args[0]).Object;
				var realArgs = CopyArgs((Scripting.Array)args[1]);
				var res = _worker.Unwrap(_m.Call(_worker.Context, self, realArgs));
				return res;
			}

			static object[] CopyArgs(Scripting.Array args)
			{
				var res = new object[args.Length];
				for (int i = 0; i < res.Length; i++) res[i] = ThreadWorker.Wrap(args[i]);
				return res;
			}
		}

		PropertyHandle _classInstanceProperty = Properties.CreateHandle();

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
					ni = new ClassInstance(this, obj, rootTable);
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
	}
}
