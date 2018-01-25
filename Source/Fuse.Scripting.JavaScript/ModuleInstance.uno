using Uno;
using Uno.Collections;
using Fuse.Scripting;

namespace Fuse.Scripting.JavaScript
{
	class ModuleInstance: DiagnosticSubject
	{
		readonly IThreadWorker _worker;
		readonly Reactive.JavaScript _js;
		readonly Dictionary<string, object> _deps = new Dictionary<string, object>();

		// UI thread
		public ModuleInstance(IThreadWorker worker, Reactive.JavaScript js)
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
			var ctx = (JSContext)context;

			var deps = new Dictionary<string, Dependency>();
			foreach (var key in _deps.Keys)
			{
				deps[key] = new Dependency{ Type = DependencyType.Explicit,
					Value = ctx.Unwrap(_deps[key]) };
			}

			var nt = _js._nameTable;
			while (nt != null)
			{
				for (int i = 0; i < nt.Entries.Length; ++i)
					deps.Add(nt.Entries[i], new Dependency{ Type = DependencyType.Name,
						Value = ctx.Unwrap(nt.Objects[i]) });
				nt = nt.ParentTable;
			}

			_js.ScriptModule.Dependencies = deps;
			EvaluateModule(context);
			ReflectExportsJS(context);
		}

		void ReflectExportsJS(Scripting.Context context)
		{
			_dc = ((JSContext)context).Reflect(_moduleResult == null ? null : _moduleResult.GetExports(context));
			UpdateManager.PostAction(SetDataContext);
		}

		//argument for PostAction callback
		object _dc;

		// UI thread
		void SetDataContext()
		{
			if (_moduleResult != null) // don't do this if we were disposed in the mean time
				_js.SetDataContext(_dc);
		}

		internal bool ReflectExports()
		{
			if (_moduleResult == null)
				return false;

			_worker.Invoke(ReflectExportsJS);
			return true;
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

		static object _resetHookMutex = new object();

		DiagnosticSubject _diagnostic = new DiagnosticSubject();

		void EvaluateModule(Scripting.Context context)
		{
			var ctx = (Context)context;

			_diagnostic.ClearDiagnostic();

			var globalId = Uno.UX.Resource.GetGlobalKey(this);

			lock (_resetHookMutex)
			{
				var newModuleResult = _js.ScriptModule.Evaluate(ctx, globalId);
				newModuleResult.AddDependency(_js.DispatchEvaluate);

				if (newModuleResult.Error == null)
					_moduleResult = newModuleResult;
				else
				{
					var se = newModuleResult.Error;

					// Don't report chain-errors of already reported errors
					if (!se.Message.Contains(ScriptModule.ModuleContainsAnErrorMessage))
						_diagnostic.SetDiagnostic(se);

					newModuleResult.Dispose();
				}
			}
		}
	}
}
