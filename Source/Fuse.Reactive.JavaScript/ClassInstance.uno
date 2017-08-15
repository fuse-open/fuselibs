using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Reactive
{
	/** Manages the lifetime of a UX class instance's representation in JavaScript modules
		within the class, dealing with disposal of resources when the related node is unrooted.
	*/
	class ClassInstance
	{
		readonly ThreadWorker _worker;
		readonly NameTable _rootTable;
		readonly object _obj;
		Scripting.Object _self;
		Dictionary<Uno.UX.Property, ObservableProperty> _properties;

		internal ObservableProperty GetObservableProperty(string name)
		{
			if (_properties != null)
				foreach (var p in _properties.Values)
					if (p.Name == name) return p;
			return null;
		}

		/** Should only be called by ThreadWorker.
			To retrieve an instance, use ThreadWorker.GetClassInstance()
		 */
		internal ClassInstance(ThreadWorker context, object obj, NameTable rootTable)
		{
			_worker = context;
			_rootTable = rootTable;
			_obj = obj;
		}

		/** Calls a function on this node instance, making the node 'this' within the function */
		public void CallMethod(Scripting.Function method, object[] args)
		{
			// TODO: Rewrite to use Function.apply() to avoid leaking this member
			_self["_tempMethod"] = method;
			_self.CallMethod("_tempMethod", args);
		}

		/** Called on JS thread when the node instance must be rooted. */
		public void EnsureRooted()
		{
			if (_self != null) return;

			var n = _obj as INotifyUnrooted;
			if (n != null) n.Unrooted += DispatchUnroot;

			_self = _worker.Unwrap(_obj) as Scripting.Object;

			if (_properties == null)
			{
				if (_rootTable != null)
				{
					EnsureHasProperties();
					for (int i = 0; i < _rootTable.Properties.Count; i++)
					{
						var p = _rootTable.Properties[i];
						if (!_properties.ContainsKey(p))
							_properties.Add(p, new LazyObservableProperty(_worker, _self, p));
					}
				}
			}
		}

		void EnsureHasProperties()
		{
			if (_properties == null) _properties = new Dictionary<Uno.UX.Property, ObservableProperty>();
		}

		void DispatchUnroot()
		{
			var n = (INotifyUnrooted)_rootTable.This;
			n.Unrooted -= DispatchUnroot;
			_worker.Invoke(Unroot);
		}

		internal Scripting.Object GetPropertyObservable(Uno.UX.Property p)
		{
			EnsureHasProperties();

			ObservableProperty op;
			if (!_properties.TryGetValue(p, out op))
			{
				op = new ObservableProperty(_worker, _self, p);
				_properties.Add(p, op);
			}
			return op.GetObservable().Object;
		}

		void Unroot()
		{
			if (_self == null) return;

			if (_properties != null)
			{
				foreach (var p in _properties.Values)
				{
					p.Reset();
				}
			}

			_self = null;
		}
	}
}