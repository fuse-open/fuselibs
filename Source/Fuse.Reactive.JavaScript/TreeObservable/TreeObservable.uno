using Uno;
using Uno.Collections;
using Fuse.Scripting;

namespace Fuse.Reactive
{
	class TreeObservable: TreeObject, IMirror
	{
		public TreeObservable(Scripting.Object obj) : base(obj)
		{
			Set(this, obj);
			Subscribe();
		}

		void Subscribe()
		{
			var obj = (Scripting.Object)Raw;
			obj["$set"] = (Callback)Set;
			obj["$add"] = (Callback)Add;
			obj["$removeAt"] = (Callback)RemoveAt;
			obj["$insertAt"] = (Callback)InsertAt;
		}

		public override void Unsubscribe()
		{
			JavaScript.Worker.Invoke(NullifyCallbacks);
		}

		void NullifyCallbacks()
		{
			var obj = (Scripting.Object)Raw;
			obj["$set"] = null;
			obj["$add"] = null;
			obj["$removeAt"] = null;
			obj["$insertAt"] = null;
		}

		Dictionary<long, ValueMirror> _reflections = new Dictionary<long, ValueMirror>();

		public object Reflect(object obj)
		{
			var id = GetId(obj);
			
			if (id > -1) 
			{
				ValueMirror res;
				
				if (_reflections.TryGetValue(id, out res))
					return res;
			}

			
			if (obj is Scripting.Object)
			{
				var so = (Scripting.Object)obj;
				var k = new TreeObject(so);
				if (id > -1)
					_reflections.Add(id, k); // Important to add to dictionary *before* calling Set
				k.Set(this, so);
				return k;
			}
			
			if (obj is Scripting.Array)
			{
				var sa = (Scripting.Array)obj;
				var k = new TreeArray(sa);
				if (id > -1)
					_reflections.Add(id, k); // Important to add to dictionary *before* calling Set
				k.Set(this, sa);
				return k;
			}

			if (obj is Scripting.Function)
				return new FunctionMirror((Scripting.Function)obj);

			return obj;
		}

		long GetId(object obj)
		{
			var func = (Function)JavaScript.Worker.Context.Evaluate("lol", "(function(obj) { if (obj instanceof Object && typeof obj.$id  !== 'undefined') return obj.$id; return -1 })");
			var res = func.Call(obj);
			if (res is double) return (long)(double)res;
			if (res is int) return (long)(int)res;
			if (res is long) return (long)res;
			return -1;
		}

		object Set(object[] args)
		{
			new SetOperation(this, args);
			return null;
		}

		object Add(object[] args)
		{
			new AddOperation(this, args);
			return null;
		}

		object RemoveAt(object[] args)
		{
			new RemoveAtOperation(this, args);
			return null;
		}

		object InsertAt(object[] args)
		{
			new InsertAtOperation(this, args);
			return null;
		}

		abstract class Operation
		{
			protected readonly TreeObservable TreeObservable;
			protected readonly object[] Arguments;
			protected Operation(TreeObservable inst, object[] args)
			{
				Arguments = args;
				TreeObservable = inst;
				UpdateManager.PostAction(PerformStart);
			}

			void PerformStart()
			{
				Perform(TreeObservable, 0);
			}

			protected abstract int SpecialArgCount { get; }
			protected abstract void Perform(object dc);

			void Perform(object dc, int pos)
			{
				if (pos > Arguments.Length - SpecialArgCount)
				{
					// Replace entire state
					TreeObservable.Set(TreeObservable, (Scripting.Object)Arguments[0]);
					return;
				}

				if (pos == Arguments.Length - SpecialArgCount)
				{
					Perform(dc);
					return;
				}

				var obj = dc as TreeObject;
				if (obj != null)
				{
					var key = Arguments[pos].ToString();
					Perform(obj[key], pos+1);
					return;
				}

				var arr = dc as TreeArray;
				if (arr != null)
				{
					var index = Marshal.ToInt(Arguments[pos]);
					Perform(arr[index], pos+1);
					return;
				}

				throw new Error("Unable to update data context. Path doesn't match exports");
			}
		}

		abstract class ValueOperation: Operation
		{
			protected ValueOperation(TreeObservable inst, object[] args): base(inst, args)
			{
				WrappedValue = inst.Reflect(args[args.Length-1]);
			}

			protected readonly object WrappedValue;
		}

		class SetOperation: ValueOperation
		{
			public SetOperation(TreeObservable inst, object[] args): base(inst, args) {}
			protected override int SpecialArgCount { get { return 2; } }

			protected override void Perform(object dc)
			{
				var key = Arguments[Arguments.Length-2];

				var obj = dc as TreeObject;
				if (obj != null) obj.Set(key.ToString(), WrappedValue, null);

				var arr = dc as TreeArray;
				if (arr != null) arr.Set(Marshal.ToInt(key), WrappedValue);
			}
		}

		class AddOperation: ValueOperation
		{
			public AddOperation(TreeObservable inst, object[] args): base(inst, args) 
			{
			}

			protected override int SpecialArgCount { get { return 1; } }
			protected override void Perform(object dc)
			{
				var arr = dc as TreeArray;
				if (arr != null) arr.Add(WrappedValue);
			}
		}

		class InsertAtOperation: ValueOperation
		{
			public InsertAtOperation(TreeObservable inst, object[] args): base(inst, args) 
			{
				_index = Marshal.ToInt(Arguments[Arguments.Length-2]);
			}
			protected override int SpecialArgCount { get { return 2; } }

			int _index;

			protected override void Perform(object dc)
			{
				var arr = dc as TreeArray;
				if (arr != null) arr.InsertAt(_index, WrappedValue);
			}
		}

		class RemoveAtOperation: Operation
		{
			public RemoveAtOperation(TreeObservable inst, object[] args): base(inst, args) 
			{
				_index = Marshal.ToInt(Arguments[Arguments.Length-1]);
			}

			int _index;

			protected override int SpecialArgCount { get { return 1; } }

			protected override void Perform(object dc)
			{
				var arr = dc as TreeArray;
				if (arr != null) arr.RemoveAt(_index);
			}
		}
	}
}