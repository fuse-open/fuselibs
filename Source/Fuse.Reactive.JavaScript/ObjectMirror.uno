using Uno.Collections;
using Uno;

namespace Fuse.Reactive
{
	class ObjectMirror : ValueMirror, IObservableObject
	{
		Dictionary<string, object> _props = new Dictionary<string, object>();

		internal ObjectMirror(ThreadWorker worker, Scripting.Object obj): base(obj)
		{
			var k = obj.Keys;
			for (int i = 0; i < k.Length; i++)
			{
				var s = k[i];
				_props.Add(s, worker.Reflect(obj[s]));
			}
		}

		public override void Unsubscribe()
		{
			foreach (var p in _props)
			{
				var d = p.Value as ValueMirror;
				if (d != null) d.Unsubscribe();
			}
		}

		public bool ContainsKey(string key)
		{
			return _props.ContainsKey(key);
		}

		public object this[string key]
		{
			get { return _props[key]; }
		}

		public string[] Keys
		{
			get { return _props.Keys.ToArray(); }
		}

		public void OnPropertyChanged(string key, object newValue)
		{
			if (_subscriptions != null) 
				_subscriptions.OnPropertyChanged(key, newValue);
		}

		Subscription _subscriptions; // Linked list

		public IDisposable Subscribe(IPropertyObserver observer)
		{
			return new Subscription(this, observer);
		}

		class Subscription : IDisposable
		{
			Subscription _next;
			ObjectMirror _om;
			IPropertyObserver _observer;
			
			public Subscription(ObjectMirror om, IPropertyObserver observer)
			{
				_om = om;
				_observer = observer;

				if (_om._subscriptions == null) _om._subscriptions = this;
				else _om._subscriptions.Append(this);
			}

			void Append(Subscription sub)
			{
				if (_next == null) _next = sub;
				else _next.Append(sub);
			}

			void Remove(Subscription sub)
			{
				if (_next == sub) _next = sub._next;
				else _next.Remove(sub);
			}

			public void Dispose()
			{
				if (_om._subscriptions == this) _om._subscriptions = _next;
				else _om._subscriptions.Remove(this);
			}

			public void OnPropertyChanged(string key, object newValue)
			{
				_observer.OnPropertyChanged(this, key, newValue);
				if (_next != null) _next.OnPropertyChanged(key, newValue);
			}
		}
	}
}