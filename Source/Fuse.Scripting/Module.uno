using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Scripting
{
	public abstract class Module: IDisposable
	{
		public object EvaluateExports(Context c, string id)
		{
			return Evaluate(c, id).GetExports(c);
		}

		public ModuleResult Evaluate(Context c, string id)
		{
			var mr = c.TryGetGlobalModuleResult(id);
			if (mr != null) return mr;

			var module = c.NewObject();
			module["exports"] = CreateExportsObject(c);
			module["disposed"] = c.NewArray();
			var result = new ModuleResult(c, id, this, module);
			if (id != null) c.RegisterGlobalModuleResult(result);

			try
			{
				Evaluate(c, result);
				MarkEvaluated();
			}
			catch (ScriptException e)
			{
				result.Error = e;
			}

			if (id != null) module["id"] = id;

			return result;
		}

		protected bool IsEvaluated { get { return _isEvaluated; } }
		
		EventHandler _evaluated;
		public event EventHandler Evaluated
		{
			add
			{
				if (_isEvaluated)
					value(null, EventArgs.Empty);
				else
					_evaluated += value;
			}
			remove { _evaluated -= value; }
		}

		bool _isEvaluated;
		void MarkEvaluated()
		{
			_isEvaluated = true;

			var handler = _evaluated;
			if (handler != null)
			{
				handler(null, EventArgs.Empty);
				_evaluated = null;
			}
		}
		/** Returns the file source that will be watched by the Context for changes in Fuse preview.
			Override in subclasses and return correct file source to support live updates
			in Fuse preview. */
		public virtual FileSource GetFile() { return null; }

		public abstract void Evaluate(Context c, ModuleResult result);

		// Override when we want to export a value of a more specific type than Object
		virtual object CreateExportsObject(Context c)
		{
			return c.NewObject();
		}
		
		public virtual void Dispose() {}
	}
}
