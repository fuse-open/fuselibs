using Uno;
using Uno.Collections;
using Fuse.Scripting;

namespace Fuse.Reactive
{
	partial class ModuleInstance
	{
		// Mutator interface
		public void DecorateModule(ModuleResult result)
		{
			var module = result.Object;
			module["set"] = (Callback)Set;
		}

		object Set(object[] args)
		{
			if (args.Length == 0) throw new Error("module.set(): at least one argument required");
			else if (args.Length == 1) JSThreadSetDataContext(args[0]);
			else 
			{
				JSThreadUpdateDataContext(((IRaw)_dc).Raw, args, 0);
				// Success! Dispatch to UI thread for update
				UpdateManager.PostAction(new SetOperation(this, args).Perform);
			}

			return null;
		}

		void JSThreadUpdateDataContext(object dc, object[] args, int pos)
		{
			var obj = dc as Scripting.Object;
			if (obj != null)
			{
				var key = args[pos].ToString();

				if (pos == args.Length - 2) obj[key] = args[args.Length - 1];
				else JSThreadUpdateDataContext(obj[key], args, pos+1);
				return;
			}

			var arr = dc as Scripting.Array;
			if (obj != null)
			{
				var index = Marshal.ToInt(args[pos]);

				if (pos == args.Length - 2) arr[index] = args[args.Length - 1];
				else JSThreadUpdateDataContext(arr[index], args, pos+1);
				return;
			}

			throw new Error("Unable to update data context. Path doesn't match exports");
		}

		class SetOperation
		{
			readonly ModuleInstance _inst;
			readonly object _args;
			public SetOperation(ModuleInstance inst, object[] args)
			{
				_inst = inst;
				_args = args;
			}

			public void Perform()
			{
				var dc = _inst._dc;
			}
		}
	}
}