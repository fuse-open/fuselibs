using Uno.Collections;

using Fuse;
using Fuse.Reactive;

namespace FuseTest
{
	/**
		An implementation of an IObservable for Uno-level data.
		
		NOTE: Taken from the charting in premiumlibs. Stuck in FuseTest for now since there is no use in fuselibs yet other than for testing.
	*/
	public abstract class ObservableData : IObservable
	{
		protected enum Flags
		{
			None = 0,
			ReadOnly = 1 << 0,
		}
		Flags _flags;
		protected ObservableData( Flags flags )
		{
			_flags = flags;
		}
		
		List<IObserver> _observers;
		
		Uno.IDisposable IObservableArray.Subscribe(IObserver observer)
		{
			if (_observers == null)
				_observers = new List<IObserver>();
		
			var wasNone = _observers.Count == 0;
			_observers.Add(observer);
			
			if (wasNone) //done after Add to ensure HasSubscription is true
				OnSubscription();
				
			OnSubscribe(observer);
			
			return _flags.HasFlag(Flags.ReadOnly) ?
				(ISubscription)new ReadOnlySubscription{ Source = this, Observer = observer }	:
				(ISubscription)new Subscription{ Source = this, Observer = observer };
		}
		
		void Unsubscribe(IObserver observer)
		{
			_observers.Remove(observer);
			
			if (_observers.Count == 0)
				OnUnsubscription();
		}

		class Subscription : ISubscription
		{
			public ObservableData Source;
			public IObserver Observer;
			
			public void Dispose()
			{
				Source.Unsubscribe(Observer);
			}
			
			void ISubscription.ClearExclusive() { Fuse.Diagnostics.InternalError( "Unsupported", this ); }
			void ISubscription.SetExclusive(object newValue) { Fuse.Diagnostics.InternalError( "Unsupported", this ); }
			void ISubscription.ReplaceAllExclusive(IArray values) { Source.ReplaceAllExclusive(values); }
		}
		
		class ReadOnlySubscription : Subscription
		{
			void ISubscription.ClearExclusive() { Fuse.Diagnostics.InternalError( "ReadOnly array", this ); }
			void ISubscription.SetExclusive(object newValue) { Fuse.Diagnostics.InternalError( "ReadOnly array", this ); }
			void ISubscription.ReplaceAllExclusive(IArray values) { Fuse.Diagnostics.InternalError( "ReadOnly array", this ); }
		}
		
		virtual protected void OnSubscription() { }
		virtual protected void OnUnsubscription() { }
		virtual protected void ReplaceAllExclusive(IArray values) {  Fuse.Diagnostics.InternalError( "Unsupported", this ); }

		protected bool HasSubscription
		{
			get { return _observers != null && _observers.Count > 0; }
		}
		
		virtual void OnSubscribe(IObserver observer)
		{
			observer.OnNewAll(this);
		}
		
		//UNO: Workaround some problems in the interface/abstract class
		abstract protected int GetLength();
		abstract protected object GetItem(int index);
		int IArray.Length { get { return GetLength();} }
		object IArray.this[int index] { get { return GetItem(index); } }
		
		protected void TriggerNewAll()
		{
			if (_observers != null)
			{
				for (int i=0; i < _observers.Count; ++i)
					_observers[i].OnNewAll(this);
			}
		}
		
		protected void TriggerClear()
		{
			if (_observers != null)
			{
				for (int i=0; i < _observers.Count; ++i)
					_observers[i].OnClear();
			}
		}
		
		protected void TriggerSet(object value)
		{
			if (_observers != null)
			{
				for (int i=0; i < _observers.Count; ++i)
					_observers[i].OnSet(value);
			}
		}
		
		protected void TriggerAdd(object value)
		{
			if (_observers != null)
			{
				for (int i=0; i < _observers.Count; ++i)
					_observers[i].OnAdd(value);
			}
		}
		
		protected void TriggerRemoveAt(int index)
		{
			if (_observers != null)
			{
				for (int i=0; i < _observers.Count; ++i)
					_observers[i].OnRemoveAt(index);
			}
		}
		
		protected void TriggerInsertAt(int index, object value)
		{
			if (_observers != null)
			{
				for (int i=0; i < _observers.Count; ++i)
					_observers[i].OnInsertAt(index, value);
			}
		}
		
		protected void TriggerNewAt(int index, object value)
		{
			if (_observers != null)
			{
				for (int i=0; i < _observers.Count; ++i)
					_observers[i].OnNewAt(index, value);
			}
		}
		
		protected void TriggerFail(string message)
		{
			if (_observers != null)
			{
				for (int i=0; i < _observers.Count; ++i)
					_observers[i].OnFailed(message);
			}
		}
	}
	
	/**
		A typed observable list. Only the owner can modify the list, for subscribers it is readonly.
	*/
	public class ObservableList<T> : ObservableData
	{
		public ObservableList()
			: base( Flags.None )
		{ }
		
		List<T> _values = new List<T>();
		public void ReplaceAll(T[] values)
		{
			_values.Clear();
			_values.AddRange(values);
			TriggerNewAll();
		}
		
		public void Clear()
		{
			_values.Clear();
			TriggerClear();
		}
		
		public void Add(T obj)
		{
			_values.Add(obj);
			TriggerAdd(obj);
		}
		
		public void RemoveAt(int index)
		{
			_values.RemoveAt(index);
			TriggerRemoveAt(index);
		}
		
		public void Insert(int index, T value)
		{
			_values.Insert(index, value);
			TriggerInsertAt(index, value);
		}
		
		public void Replace(int index, T value)
		{
			_values.RemoveAt(index);
			_values.Insert(index, value);
			TriggerNewAt(index, value);
		}
		
		protected override int GetLength()
		{
			return _values.Count;
		}
		
		protected override object GetItem(int index)
		{
			return _values[index];
		}
		
		protected override void ReplaceAllExclusive(IArray values)
		{
			_values.Clear();
			for (int i=0; i < values.Length; ++i)
				_values.Add( (T)values[i]);
		}
		
		public int Count { get { return _values.Count; } }
		public T this[int index] { get { return _values[index]; } }
	}
	
	/**
		A typed observable for a single data object. Only the owner can modify the value, for subscribers it is readonly.
	*/
	public class ReadOnlyObservableData<T> : ObservableData where T : object
	{
		public ReadOnlyObservableData() 
			: base( Flags.ReadOnly )
		{ }
		
		public ReadOnlyObservableData( T initialValue )
			: base( Flags.ReadOnly )
		{
			_value = initialValue;
		}
		
		override void OnSubscribe(IObserver observer)
		{
			observer.OnSet(_value);
		}
		
		T _value;
		public void Set(T value)
		{
			_value = value;
			TriggerSet(_value);
		}
		
		public T Value { get { return _value; } }
		
		public void Clear()
		{
			_value = null;
			TriggerClear();
		}
		
		protected override int GetLength()
		{
			return _value == null ? 0 : 1;
		}
		
		protected override object GetItem(int index)
		{
			return _value;
		}
	}
	
}
