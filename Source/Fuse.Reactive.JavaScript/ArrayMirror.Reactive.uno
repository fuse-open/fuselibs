using Uno.Collections;
using Uno;

namespace Fuse.Reactive
{
	partial class ArrayMirror
	{
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
		}

		internal void Set(int index, object newValue)
		{
			ValueMirror.Unsubscribe(_items[index]);

			_items[index] = newValue;

			var sub = Subscribers as ArraySubscription;
			if (sub != null) 
				sub.OnReplaceAt(index, newValue);
		}
	}
}