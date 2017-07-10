using Uno;
using Uno.Collections;
using Fuse.Scripting;

namespace Fuse.Reactive
{
	partial class ModuleInstance: DiagnosticSubject
	{
		readonly ThreadWorker _worker;
		readonly JavaScript _js;
		readonly Dictionary<string, object> _deps = new Dictionary<string, object>();

		// UI thread
		public ModuleInstance(ThreadWorker worker, JavaScript js)
		{
			for (var i = 0; i < js.Dependencies.Count; i++)
				_deps.Add(js.Dependencies[i].Name, worker.Unwrap(js.Dependencies[i].Value));

			_js = js;
			_worker = worker;
			_worker.Invoke(Evaluate);
		}

		// JS thread
		void Evaluate()
		{
			_js.ScriptModule.Dependencies = _deps;
			JSThreadSetDataContext(EvaluateExports());
		}

		void JSThreadSetDataContext(object dc)
		{
			_dc = _worker.Reflect(dc);
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

		extern(!FUSELIBS_NO_TOASTS) static string previousErrorFile;
		DiagnosticSubject _diagnostic = new DiagnosticSubject();

		void EvaluateModule()
		{
			_diagnostic.ClearDiagnostic();

			var globalId = Uno.UX.Resource.GetGlobalKey(this);

			lock (_resetHookMutex)
			{
				var newModuleResult = _js.ScriptModule.EvaluateInstance(_worker.Context, globalId, this);
				newModuleResult.AddDependency(_js.DispatchEvaluate);

				if (newModuleResult.Error == null)
				{
					_moduleResult = newModuleResult;
					if defined(!FUSELIBS_NO_TOASTS)
					{
						if (previousErrorFile == _js.FileName + _js.LineNumber)
						{
							Diagnostics.UserSuccess("JavaScript error in " + _js.FileName + " fixed!", this);
							previousErrorFile = null;
						}
					}
				}
				else
				{
					var se = newModuleResult.Error;

					// Don't report chain-errors of already reported errors
					if (!se.Message.Contains(ScriptModule.ModuleContainsAnErrorMessage))
					{
						if defined(FUSELIBS_NO_TOASTS)
							_diagnostic.SetDiagnostic(se);
						else
						{
							JavaScript.UserScriptError( "JavaScript error", se, this );
							previousErrorFile = _js.FileName + _js.LineNumber;
						}
					}
				}
			}
		}
	}
}