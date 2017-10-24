using Uno;
using Uno.UX;
using Uno.Collections;
using Fuse.Scripting;
using Uno.Testing;
using Uno.Threading;

namespace Fuse.Scripting.JavaScript
{
	class RootableScriptModule: ScriptModule
	{
		readonly ThreadWorker _worker;
		readonly NameTable _names;
		ClassInstance _classInstance;

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
			if (_classInstance == null) _classInstance = _worker.GetClassInstance(_names);
			_classInstance.EnsureRooted(c);
		}

		internal Dictionary<string, object> Dependencies;

		protected override Dictionary<string, object> GenerateRequireTable(Scripting.Context c)
		{
			return Dependencies;
		}

		protected override string GenerateArgs(Scripting.Context c, ModuleResult result, List<object> args)
		{
			var argsString = base.GenerateArgs(c, result, args);

			foreach (var dep in Dependencies) 
			{
				argsString += ", " + dep.Key;
				args.Add(dep.Value);
			}

			return argsString;
		}

		protected override void CallModuleFunc(Function moduleFunc, object[] args)
		{
			_classInstance.CallMethod(moduleFunc, args);
		}
	}
}
