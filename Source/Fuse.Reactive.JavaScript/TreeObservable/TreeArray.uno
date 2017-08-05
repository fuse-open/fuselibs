using Uno.Collections;
using Uno;

namespace Fuse.Reactive
{
	class TreeArray : ArrayMirror, IObservableArray
	{
		internal TreeArray(Scripting.Array arr): base(arr) {}

		public IDisposable Subscribe(IObserver observer)
		{
			return new ArraySubscription(this, observer);
		}

		class ArraySubscription: Subscription
		{
			readonly IObserver _observer;

			public ArraySubscription(ArrayMirror am, IObserver observer): base(am)
			{
				_observer = observer;
			}

			public void OnReplaceAt(int index, object newValue)
			{
				_observer.OnNewAt(index, newValue);
				var next = Next as ArraySubscription;
				if (next != null) next.OnReplaceAt(index, newValue);
			}

			public void OnAdd(object newValue)
			{
				_observer.OnAdd(newValue);
				var next = Next as ArraySubscription;
				if (next != null) next.OnAdd(newValue);
			}

			public void OnInsertAt(int index, object newValue)
			{
				_observer.OnInsertAt(index, newValue);
				var next = Next as ArraySubscription;
				if (next != null) next.OnInsertAt(index, newValue);
			}

			public void OnRemoveAt(int index)
			{
				_observer.OnRemoveAt(index);
				var next = Next as ArraySubscription;
				if (next != null) next.OnRemoveAt(index);
			}
		}

		internal void Set(int index, object newValue)
		{
			ValueMirror.Unsubscribe(_items[index]);

			_items[index] = newValue;

			var sub = Subscribers as ArraySubscription;
			if (sub != null) 
				sub.OnReplaceAt(index, newValue);
		}

		internal void Add(object value)
		{
			_items.Add(value);
			var sub = Subscribers as ArraySubscription;
			if (sub != null) 
				sub.OnAdd(value);
		}

		internal void InsertAt(int index, object value)
		{
			_items.Insert(index, value);
			var sub = Subscribers as ArraySubscription;
			if (sub != null) 
				sub.OnInsertAt(index, value);
		}

		internal void RemoveAt(int index)
		{
			_items.RemoveAt(index);
			var sub = Subscribers as ArraySubscription;
			if (sub != null) 
				sub.OnRemoveAt(index);
		}
	}
}