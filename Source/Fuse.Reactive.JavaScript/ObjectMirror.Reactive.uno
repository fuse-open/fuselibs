using Uno.Collections;
using Uno;

namespace Fuse.Reactive
{
	partial class ObjectMirror 
	{
		public IDisposable Subscribe(IPropertyObserver observer)
		{
			return new PropertySubscription(this, observer);
		}

		class PropertySubscription : Subscription
		{
			readonly IPropertyObserver _observer;
			
			public PropertySubscription(ObjectMirror om, IPropertyObserver observer): base(om)
			{
				_observer = observer;
			}

			public void OnPropertyChanged(string key, object newValue)
			{
				_observer.OnPropertyChanged(this, key, newValue);
				var next = Next as PropertySubscription;
				if (next != null) next.OnPropertyChanged(key, newValue);
			}
		}

		internal void Set(string key, object newValue)
		{
			ValueMirror.Unsubscribe(_props[key]);

			_props[key] = newValue;

			var sub = Subscribers as PropertySubscription;
			if (sub != null) 
				sub.OnPropertyChanged(key, newValue);
		}
	}
}