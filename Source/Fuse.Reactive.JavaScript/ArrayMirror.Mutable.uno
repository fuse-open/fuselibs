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

		void IMutable.Set(object[] args, int pos)
		{
			var index = Marshal.ToInt(args[pos]);
			if (pos < args.Length - 2)
			{
				var m = (IMutable)_items[index];
				m.Set(args, pos+1);
			}
			else
			{
				Set(index, args[pos+1]);				
			}
		}

		void Set(int index, object newValue)
		{
			_items[index] = newValue;

			var sub = Subscribers as ArraySubscription;
			if (sub != null) 
				sub.OnReplaceAt(index, newValue);
		}
	}
}