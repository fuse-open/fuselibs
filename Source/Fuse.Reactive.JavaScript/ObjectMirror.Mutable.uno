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

		void IMutable.Set(object[] args, int pos)
		{
			var key = args[pos].ToString();
			if (pos < args.Length - 2)
			{
				var m = (IMutable)_props[key];
				m.Set(args, pos+1);
			}
			else
			{
				Set(key, args[pos+1]);				
			}
		}

		void Set(string key, object newValue)
		{
			_props[key] = newValue;

			var sub = Subscribers as PropertySubscription;
			if (sub != null) 
				sub.OnPropertyChanged(key, newValue);
		}
	}
}