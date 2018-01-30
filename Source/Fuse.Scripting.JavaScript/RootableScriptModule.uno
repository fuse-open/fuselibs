using Uno;
using Uno.UX;
using Uno.Collections;
using Fuse.Scripting;
using Uno.Testing;
using Uno.Threading;

namespace Fuse.Scripting.JavaScript
{
	public enum ScriptModuleNames
	{
		/** All names are injected with the same name they have in UX. */
		InjectAll,
		/** UX names are not injected but still available via `require("ux:name")` */
		Require,
	}
	
	class RootableScriptModule: ScriptModule
	{
		readonly ThreadWorker _worker;
		readonly NameTable _names;
		ClassInstance _classInstance;

		ScriptModuleNames _moduleNames = ScriptModuleNames.InjectAll;
		public ScriptModuleNames ModuleNames
		{
			get { return _moduleNames; }
			set { _moduleNames = value; }
		}
		
		public RootableScriptModule(ThreadWorker worker, NameTable names)
		{
			_worker = worker;
			_names = names;
		}

		public override void Evaluate(Scripting.Context c, ModuleResult result)
		{
			EnsureClassInstanceRooted(c);
			base.Evaluate(c, result);
		}

		void EnsureClassInstanceRooted(Scripting.Context c)
		{
			if (_names != null)
			{
				if (_classInstance == null) _classInstance = ((JSContext)c).GetClassInstance(_names);
				_classInstance.EnsureRooted(c);
			}
		}

		internal Dictionary<string, Dependency> Dependencies;

		internal override Dictionary<string, Dependency> GenerateRequireTable(Scripting.Context c)
		{
			return Dependencies;
		}

		internal override string GenerateArgs(Scripting.Context c, ModuleResult result, List<object> args)
		{
			var argsString = base.GenerateArgs(c, result, args);

			foreach (var dep in Dependencies) 
			{
				if (dep.Value.Type == DependencyType.Name && ModuleNames != ScriptModuleNames.InjectAll)
					continue;
					
				argsString += ", " + dep.Key;
				args.Add(dep.Value.Value);
			}

			return argsString;
		}

		internal override void CallModuleFunc(Context context, Function moduleFunc, object[] args)
		{
			if (_classInstance != null)
				_classInstance.CallMethod(context, moduleFunc, args);
			else
				moduleFunc.Call(context, args);
		}
	}
}
