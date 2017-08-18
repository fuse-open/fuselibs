using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Reactive
{
	class LazyObservableProperty: ObservableProperty
	{
		public LazyObservableProperty(ThreadWorker w, Scripting.Object obj, Uno.UX.Property p): base(w, obj, p)
		{
			w.Context.ObjectDefineProperty(obj, p.Name.ToString(), Get);	
		}

		object Get(object[] args)
		{
			return _worker.Unwrap(GetObservable());
		}
	}

	/** A wrapper for a weak observable on the JS side.
		The backing observable can be disposed (e.g. when the associated view is unrooted)
		and then re-created on demand on calls to GetObservable().

		This prevents leakage of strong references to observables on the JS side.
	*/
	class ObservableProperty: IObserver, IPropertyListener
	{
		protected readonly ThreadWorker _worker;
		Uno.UX.Property _property;
		Scripting.Object _obj;

		public ObservableProperty(ThreadWorker w, Scripting.Object obj, Uno.UX.Property p)
		{
			_obj = obj;
			_worker = w;
			_property = p;
		}

		public string Name { get { return _property.Name; } }

		Observable _observable;

		internal Observable GetObservable()
		{
			if (_observable == null)
			{
				_observable = Observable.Create(_worker);	
				Subscribe();
			}
			return _observable;
		}

		ISubscription _subscription;
		void Subscribe()
		{
			_subscription = _observable.Subscribe(this);
			PushValue(_property.GetAsObject());
			_property.AddListener(this);
		}

		public void Reset()
		{
			if (_subscription != null)
			{
				_subscription.Dispose();
				_subscription = null;
				_property.RemoveListener(this);
			}

			if (_observable != null)
			{
				_observable.Unsubscribe();
				_observable = null;
			}
		}

		void IObserver.OnClear()
		{
			if (_property.PropertyType.IsClass)
				_property.SetAsObject(null, this);
		}

		void IObserver.OnNewAll(IArray values)
		{
			if (values.Length == 1) Set(values[0]);
		}
		void IObserver.OnNewAt(int index, object newValue)
		{
			if (index == 0) Set(newValue);
		}
		void IObserver.OnSet(object newValue)
		{
			Set(newValue);
		}
		void IObserver.OnAdd(object addedValue)
		{
			// Not supported
		}
		void IObserver.OnRemoveAt(int index)
		{
			// Not supported
		}
		void IObserver.OnInsertAt(int index, object value)
		{
			if (index == 0) Set(value);
		}
		void IObserver.OnFailed(string message)
		{
			// Not supported
		}

		void Set(object value)
		{
			object res;
			if (Marshal.TryConvertTo(_property.PropertyType, value, out res, this))
				_property.SetAsObject(res, this);
		}

		void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector prop)
		{
			if (prop != _property.Name) return;
			if (obj != _property.Object) return;
			if (_subscription == null) return;

			_worker.Invoke(new PushCapture(PushValue, _property.GetAsObject()).Run);
		}

		class PushCapture
		{
			readonly Action<object> _push;
			readonly object _arg;

			public PushCapture(Action<object> push, object arg)
			{
				_push = push;
				_arg = arg;
			}

			public void Run()
			{
				_push(_arg);
			}
		}

		void PushValue(object val)
		{
			if (val != null)
			{
				_subscription.SetExclusive(val);	
			}
			else
			{
				_subscription.ClearExclusive();
			}
		}
	}
}
