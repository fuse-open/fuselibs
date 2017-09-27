using Uno;

namespace Fuse.Reactive
{
	/** Implements subscription subject with a fast linked list of disposable subscriptions-
		This is intended as the base class of ValueMirro.
	*/
	abstract class SubscriptionSubject
	{
		Subscription _subscribers; // Linked list;

		protected Subscription Subscribers { get { return _subscribers; } }

		protected internal abstract class Subscription: IDisposable
		{
			Subscription _next, _prev;

			protected Subscription Next { get { return _next; } }

			readonly SubscriptionSubject _s;
			protected SubscriptionSubject SubscriptionSubject { get { return _s; } }

			protected Subscription(SubscriptionSubject s)
			{
				_s = s;
				
				if (s._subscribers == null) s._subscribers = this;
				else 
				{
					_next = s._subscribers;
					_next._prev = this;
					s._subscribers = this;
				}
			}

			public void Dispose()
			{
				if (_s._subscribers == this)
				{
					_s._subscribers = _next;
					if (_next != null) _next._prev = null;
				}
				else
				{
					_prev._next = _next;
					if (_next != null)	_next._prev = _prev;
				}
			}
		}
	}
}