using Uno;
using Uno.Collections;
using Uno.Text;
using Uno.Threading;
using Uno.IO;
using Uno.UX;

namespace Fuse.Scripting
{
	public interface IThreadWorker
	{
		void Invoke(Uno.Action<Scripting.Context> action);

		[Obsolete("Use Invoke(Action<Context>) instead")]
		void Invoke(Uno.Action action);
	}

	internal interface IFunctionMirror
	{
		Function Function { get; }
	}

	public abstract class Context: Uno.IDisposable
	{
		IDictionary<string, ModuleResult> _moduleResults = new ConcurrentDictionary<string, ModuleResult>();

		public void RegisterGlobalModuleResult(ModuleResult result)
		{
			if (result.Id == null) return;

			_moduleResults.Add(result.Id, result);
		}

		public ModuleResult TryGetGlobalModuleResult(string id)
		{
			if (id == null) return null;

			if (_moduleResults.ContainsKey(id)) return _moduleResults[id];
			return null;
		}

		internal void DeleteGlobalModuleResult(ModuleResult mr)
		{
			if (mr.Id == null) return;

			if (_moduleResults.ContainsKey(mr.Id))
				_moduleResults.Remove(mr.Id);
		}

		protected Context()
		{
		}

		public abstract IThreadWorker ThreadWorker { get; }

		public abstract object Wrap(object obj);
		public abstract object Unwrap(object obj);
		public abstract object Reflect(object obj);

		public void Invoke(Uno.Action<Scripting.Context> action)
		{
			ThreadWorker.Invoke(action);
		}

		[Obsolete("Use Invoke(Action<Context>) instead")]
		public void Invoke(Uno.Action action)
		{
			ThreadWorker.Invoke(action);
		}

		Function _identity;

		public Function CallbackToFunction(Callback c)
		{
			if (_identity == null) 
				_identity = (Function)Evaluate("(Context)", "(function(x) { return x; })");

			return (Function)_identity.Call(this, c);
		}

		public void ObjectDefineProperty(Object obj, string name, Callback getProperty, Callback setProperty = null, bool enumerable = false, bool configurable = false)
		{
			var func = Evaluate(name, "(function(obj, name, getCallback, setCallback, e, c) { Object.defineProperty(obj, name, { get: getCallback, "
				+ (setProperty != null ? " set: setCallback," : "") + " enumerable: e, configurable: c }); })") as Scripting.Function;
			func.Call(this, obj, name, getProperty, setProperty, enumerable, configurable);
		}

		public void ObjectDefineProperty(Object obj, string name, object value, bool enumerable = false, bool configurable = false)
		{
			var func = Evaluate(name, "(function(obj, name, value, e, c) { Object.defineProperty(obj, name, { value: value, enumerable: e, configurable: c }); })") as Scripting.Function;
			func.Call(this, obj, name, value, enumerable, configurable);
		}

		public Object ObjectCreate(params object[] args)
		{
			var objectCreate = Evaluate("(Context)", "Object.create") as Scripting.Function;
			if(objectCreate != null)
				return objectCreate.Call(this, args) as Scripting.Object;

			return null;
		}

		Function _parseJson;
		public object ParseJson(string json)
		{
			if (_parseJson == null)
				_parseJson = (Function)Evaluate("(Context)", "JSON.parse");

			return _parseJson.Call(this, json);
		}

		Function _newObject;
		public Object NewObject()
		{
			if (_newObject == null) _newObject = (Function)Evaluate("(Context)", "(function() { return new Object; })");
			return (Object)_newObject.Call(this);
		}

		Function _newArray;
		public Array NewArray(params object[] values)
		{
			if (_newArray == null) _newArray = (Function)Evaluate("(Context)", "(function(count) { return new Array(count); })");
			var a = (Array)_newArray.Call(this, values.Length);
			for (int i = 0; i < values.Length; i++) a[i] = values[i];
			return a;
		}

		Function _newError;
		public Object NewError(params object[] args)
		{
			_newError = GlobalObject["Error"] as Function;
			return _newError.Construct(this, args);
		}

		public abstract object Evaluate(string fileName, string code);
		public abstract Object GlobalObject { get; }
		public abstract void Dispose();
	}
}
