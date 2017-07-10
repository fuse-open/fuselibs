using Uno;
using Uno.Collections;
using Fuse.Scripting;

namespace Fuse.Reactive
{
	interface IMutable
	{
		void Set(object[] args, int pos);
	}

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
			else new SetOperation(this, args).JSThreadPerform();
			return null;
		}

		class SetOperation
		{
			readonly ModuleInstance _inst;
			readonly object[] _args;
			public SetOperation(ModuleInstance inst, object[] args)
			{
				_inst = inst;
				_args = args;
			}

			void UIThreadPerform()
			{
				var dc = (IMutable)_inst._dc;
				dc.Set(_args, 0);
			}

			public void JSThreadPerform()
			{
				var raw = ((IRaw)_inst._dc).Raw;
				JSThreadPerform(raw, 0);
				UpdateManager.PostAction(UIThreadPerform);
			}

			void JSThreadPerform(object dc, int pos)
			{
				var obj = dc as Scripting.Object;
				if (obj != null)
				{
					var key = _args[pos].ToString();

					if (pos == _args.Length - 2) obj[key] = _args[_args.Length - 1];
					else JSThreadPerform(obj[key], pos+1);
					return;
				}

				var arr = dc as Scripting.Array;
				if (obj != null)
				{
					var index = Marshal.ToInt(_args[pos]);

					if (pos == _args.Length - 2) arr[index] = _args[_args.Length - 1];
					else JSThreadPerform(arr[index], pos+1);
					return;
				}

				throw new Error("Unable to update data context. Path doesn't match exports");
			}
		}
	}
}