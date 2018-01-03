using Uno;

namespace Fuse.Reactive
{
	/** Utility base class that observes the first value of an `IObservable`.
		
		Note that this class should only be used with instances that support `IObservable`, 
		not just `IObservableArray`. This ensures the collection is semantically inteneded
		for single-value use.
	*/
	abstract class ValueObserver: IDisposable, IObserver
	{
		IDisposable _obsSub;
		IObservable _obs;

		public IObservable Observable { get { return _obs; } }

		protected object Value
		{
			get 
			{ 
				if (_obs == null) return null;
				if (_obs.Length == 0) return null;
				return _obs[0];
			}
		}

		/** Calling this method will push the current `value[0]` if available, and then
			subscribe to changes.
		*/
		protected void Subscribe(IObservable obs)
		{
			_obs = obs;
			if (obs.Length > 0) PushData(obs[0]);
			_obsSub = obs.Subscribe(this);
		}

		protected void SubscribeNoPush(IObservable obs)
		{
			_obs = obs;
			_obsSub = obs.Subscribe(this);
		}
		
		protected void Unsubscribe()
		{
			if (_obsSub != null) _obsSub.Dispose();
			_obsSub = null;
			_obs = null;
		}

		public virtual void Dispose()
		{
			Unsubscribe();
		}

		protected abstract void PushData(object newValue);
		protected abstract void LostData();
		
		void IObserver.OnClear()
		{
			LostData();
		}

		void IObserver.OnSet(object newValue)
		{
			PushData(newValue);				
		}

		void IObserver.OnAdd(object addedValue)
		{
			PushData(_obs[0]);
		}

		void IObserver.OnNewAt(int index, object value)
		{
			PushData(_obs[0]);
		}

		void IObserver.OnFailed(string message)
		{
			LostData();
		}

		void IObserver.OnNewAll(IArray values)
		{
			if (values.Length > 0)
				PushData(_obs[0]);
			else
				LostData();
		}

		void IObserver.OnRemoveAt(int index)
		{
			if (_obs.Length > 0)
				PushData(_obs[0]);
			else
				LostData();
		}

		void IObserver.OnInsertAt(int index, object value)
		{
			PushData(_obs[0]);
		}
	}

	class ValueForwarder: ValueObserver
	{
		public interface IValueListener 
		{ 
			void NewValue(object value); 
			void LostValue();
		}

		IValueListener _listener;
		public ValueForwarder(IObservable obs, IValueListener listener)
		{
			_listener = listener;
			Subscribe(obs);
		}

		protected override void PushData(object newValue)
		{
			_listener.NewValue(newValue);
		}
		protected override void LostData()
		{
			_listener.LostValue();
		}
	}
}
