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
			if (_classInstance == null) _classInstance = _worker.GetClassInstance(_names);
			_classInstance.EnsureRooted();
		}

		internal Dictionary<string, object> Dependencies;

		protected override string GenerateArgs(Context c, ModuleResult result, List<object> args)
		{
			var argsString = base.GenerateArgs(c, result, args);

			foreach (var dep in Dependencies) 
			{
				var key = IsReservedKeyword(dep.Key) ? "$" + dep.Key : dep.Key;
				argsString += ", " + key;
				args.Add(dep.Value);
			}

			var nt = _names;
			while (nt != null)
			{
				for (int i = 0; i < nt.Entries.Length; ++i)
				{
					var name = nt.Entries[i];
					var key = IsReservedKeyword(name) ? "$" + name : name;
					argsString += ", " + nt.Entries[i];
					args.Add(_worker.Unwrap(nt.Objects[i]));
				}
				nt = nt.ParentTable;
			}

			return argsString;
		}

		// Taken from the ECMAScript 5.1 Standard
		// https://www.ecma-international.org/publications/files/ECMA-ST-ARCH/ECMA-262%205th%20edition%20December%202009.pdf
		static HashSet<string> _reservedKeywords = new HashSet<string>()
		{
			"break", "do", "instanceof", "typeof",
			"case", "else", "new", "var",
			"catch", "finally", "return", "void",
			"continue", "for", "switch", "while",
			"debugger", "function", "this", "with",
			"default", "if", "throw",
			"delete", "in", "try"
		};

		static bool IsReservedKeyword(string s)
		{
			return _reservedKeywords.Contains(s);
		}

		protected override void CallModuleFunc(Function moduleFunc, object[] args)
		{
			_classInstance.CallMethod(moduleFunc, args);
		}
	}
}
