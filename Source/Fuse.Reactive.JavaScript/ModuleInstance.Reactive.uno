using Uno;
using Uno.Collections;
using Fuse.Scripting;

namespace Fuse.Reactive
{
	interface IReactive
	{
		void Set(object[] args, int pos);
		void Push(object[] args, int pos);
	}

	partial class ModuleInstance
	{
		// Reactive module interface
		public void DecorateModule(ModuleResult result)
		{
			var module = result.Object;
			_dc = _worker.Reflect(module["exports"]);
			module["set"] = (Callback)Set;
			module["push"] = (Callback)Push;
		}

		object Set(object[] args)
		{
			if (args.Length == 0) throw new Error("module.set(): at least one argument required");
			else if (args.Length == 1) 
			{
				ValueMirror.Unsubscribe(_dc);
				_dc = _worker.Reflect(args[0]);
				UpdateManager.PostAction(SetDataContext);
			}
			else new SetOperation(this, args).JSThreadPerform();
			return null;
		}

		object Push(object[] args)
		{
			if (args.Length == 0) throw new Error("module.push(): at least one argument required");
			else new PushOperation(this, args).JSThreadPerform();
			return null;
		}

		abstract class Operation
		{
			protected readonly ModuleInstance ModuleInstance;
			protected readonly object[] Arguments;
			protected Operation(ModuleInstance inst, object[] args)
			{
				Arguments = args;
				ModuleInstance = inst;
			}

			void UIThreadPerform()
			{
				var dc = (IReactive)ModuleInstance._dc;
				dc.Set(Arguments, 0);
			}

			public void JSThreadPerform()
			{
				var raw = ((IRaw)ModuleInstance._dc).Raw;
				JSThreadPerform(raw, 0);
				UpdateManager.PostAction(UIThreadPerformStart);
			}

			void UIThreadPerformStart()
			{
				UIThreadPerform(ModuleInstance._dc, 0);
			}

			protected abstract int SpecialArgCount { get; }
			protected abstract void JSThreadPerform(object dc);
			protected abstract void UIThreadPerform(object dc);

			void JSThreadPerform(object dc, int pos)
			{
				if (pos == Arguments.Length - SpecialArgCount)
				{
					JSThreadPerform(dc);
					return;
				}

				var obj = dc as Scripting.Object;
				if (obj != null)
				{
					var key = Arguments[pos].ToString();
					JSThreadPerform(obj[key], pos+1);
					return;
				}

				var arr = dc as Scripting.Array;
				if (obj != null)
				{
					var index = Marshal.ToInt(Arguments[pos]);
					JSThreadPerform(arr[index], pos+1);
					return;
				}

				throw new Error("Unable to update data context. Path doesn't match exports");
			}

			void UIThreadPerform(object dc, int pos)
			{
				if (pos == Arguments.Length - SpecialArgCount)
				{
					UIThreadPerform(dc);
					return;
				}

				var obj = dc as ObjectMirror;
				if (obj != null)
				{
					var key = Arguments[pos].ToString();
					UIThreadPerform(obj[key], pos+1);
					return;
				}

				var arr = dc as ArrayMirror;
				if (obj != null)
				{
					var index = Marshal.ToInt(Arguments[pos]);
					UIThreadPerform(arr[index], pos+1);
					return;
				}

				throw new Error("Unable to update data context. Path doesn't match exports");
			}
		}

		class SetOperation: Operation
		{
			public SetOperation(ModuleInstance inst, object[] args): base(inst, args) {}

			object _wrappedValue;

			protected override int SpecialArgCount { get { return 2; } }
			protected override void JSThreadPerform(object dc)
			{
				var key = Arguments[Arguments.Length-2];
				var value = Arguments[Arguments.Length-1];
				_wrappedValue = ModuleInstance._worker.Reflect(value);

				var obj = dc as Scripting.Object;
				if (obj != null) 
				{
					obj[key.ToString()] = value;
					return;
				}

				var arr = dc as Scripting.Array;
				if (arr != null) 
				{
					arr[Marshal.ToInt(key)] = value;
					return;
				}

				throw new Error("module.set(): Path mistmatch");
			}

			protected override void UIThreadPerform(object dc)
			{
				var key = Arguments[Arguments.Length-2];

				var obj = dc as ObjectMirror;
				if (obj != null) obj.Set(key.ToString(), _wrappedValue);

				var arr = dc as ArrayMirror;
				if (arr != null) arr.Set(Marshal.ToInt(key), _wrappedValue);
			}
		}

		class PushOperation: Operation
		{
			public PushOperation(ModuleInstance inst, object[] args): base(inst, args) {}

			object _wrappedValue;

			protected override int SpecialArgCount { get { return 1; } }
			protected override void JSThreadPerform(object dc)
			{
				var value = Arguments[Arguments.Length-1];
				_wrappedValue = ModuleInstance._worker.Reflect(value);

				var arr = dc as Scripting.Array;
				if (arr != null)
				{
					ModuleInstance._worker.Push(arr, value);
					return;
				}

				throw new Error("module.push(): Path mistmatch");
			}

			protected override void UIThreadPerform(object dc)
			{
				var arr = dc as ArrayMirror;
				if (arr != null) arr.Push(_wrappedValue);
			}
		}
	}
}