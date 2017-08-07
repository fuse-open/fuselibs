using Uno;
using Uno.UX;
using Uno.Collections;
using Fuse.Scripting;
using Uno.Testing;
using Uno.Threading;

namespace Fuse.Reactive
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

		public override void Evaluate(Context c, ModuleResult result)
		{
			EnsureClassInstanceRooted();
			base.Evaluate(c, result);
		}

		void EnsureClassInstanceRooted()
		{
			if (_names != null) 
			{
				if (_classInstance == null) _classInstance = _worker.GetClassInstance(_names);
				_classInstance.EnsureRooted();
			}
		}

		internal Dictionary<string, object> Dependencies;

		protected override string GenerateArgs(Context c, ModuleResult result, List<object> args)
		{
			var argsString = base.GenerateArgs(c, result, args);

			foreach (var dep in Dependencies) 
			{
				argsString += ", " + dep.Key;
				args.Add(dep.Value);
			}

			var nt = _names;
			while (nt != null)
			{
				for (int i = 0; i < nt.Entries.Length; ++i)
				{
					argsString += ", " + nt.Entries[i];
					args.Add(_worker.Unwrap(nt.Objects[i]));
				}
				nt = nt.ParentTable;
			}

			return argsString;
		}

		protected override void CallModuleFunc(Function moduleFunc, object[] args)
		{
			if (_classInstance != null)
				_classInstance.CallMethod(moduleFunc, args);
			else
				moduleFunc.Call(args);
		}
	}
}
