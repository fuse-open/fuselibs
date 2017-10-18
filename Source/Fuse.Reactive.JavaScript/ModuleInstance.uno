using Uno;
using Uno.Collections;
using Fuse.Scripting;

namespace Fuse.Reactive
{
	class ModuleInstance: DiagnosticSubject
	{
		readonly ThreadWorker _worker;
		readonly JavaScript _js;
		readonly Dictionary<string, object> _deps = new Dictionary<string, object>();

		// UI thread
		public ModuleInstance(ThreadWorker worker, JavaScript js)
		{
			for (var i = 0; i < js.Dependencies.Count; i++)
				_deps.Add(js.Dependencies[i].Name, js.Dependencies[i].Value);

			_js = js;
			_worker = worker;
			_worker.Invoke(Evaluate);
		}

		// JS thread
		void Evaluate(Scripting.Context context)
		{
			var deps = new Dictionary<string, object>();
			foreach (var key in _deps.Keys)
			{
				deps[key] = _worker.Unwrap(_deps[key]);
			}

			var nt = _js._nameTable;
			while (nt != null)
			{
				for (int i = 0; i < nt.Entries.Length; ++i)
					deps.Add(nt.Entries[i], _worker.Unwrap(nt.Objects[i]));
				nt = nt.ParentTable;
			}

			_js.ScriptModule.Dependencies = deps;
			_dc = _worker.Reflect(EvaluateExports());
			UpdateManager.PostAction(SetDataContext);
		}

		object _dc;

		// UI thread
		void SetDataContext()
		{
			if (_moduleResult != null) // don't do this if we were disposed in the mean time
				_js.SetDataContext(_dc);
		}

		ModuleResult _moduleResult;

		public void Dispose()
		{
			ClearDiagnostic();

			if (_moduleResult != null)
			{
				_moduleResult.Dispose();
				_moduleResult = null;
			}
		}

		object EvaluateExports()
		{
			EvaluateModule();

			if (_moduleResult != null)
				return _moduleResult.Object["exports"];

			return null;
		}

		static object _resetHookMutex = new object();

		DiagnosticSubject _diagnostic = new DiagnosticSubject();

		void EvaluateModule()
		{
			_diagnostic.ClearDiagnostic();

			var globalId = Uno.UX.Resource.GetGlobalKey(this);

			lock (_resetHookMutex)
			{
				var newModuleResult = _js.ScriptModule.Evaluate(_worker.Context, globalId);
				newModuleResult.AddDependency(_js.DispatchEvaluate);

				if (newModuleResult.Error == null)
					_moduleResult = newModuleResult;
				else
				{
					var se = newModuleResult.Error;

					// Don't report chain-errors of already reported errors
					if (!se.Message.Contains(ScriptModule.ModuleContainsAnErrorMessage))
						_diagnostic.SetDiagnostic(se);
				}
			}
		}
	}
}
