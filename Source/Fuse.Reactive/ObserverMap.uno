using Uno;
using Uno.Collections;

namespace Fuse.Reactive
{
	//UNO: Cast to IArray was failing if this class is declared inside ObserverMap
	class UnmappedView<T> : IArray where T : class
	{
		ObserverMap<T> _source;
		public UnmappedView( ObserverMap<T> source )
		{
			_source = source;
		}
		
		public int Length { get { return _source._list.Count; } } 
		public object this[int index] { get { return _source.UVUnmap(_source._list[index]); } }
	}
	
	/**
		A two-way mapped observable list. This serves as the outermost list: the list functions here will update the backing
		Observable.
	*/
	abstract class ObserverMap<T> : IObserver, IArray where T : class
	{
		internal List<T> _list = new List<T>();
		
		protected abstract T Map(object v);
		protected abstract object Unmap(T mv);
	
		internal object UVUnmap(T mv) { return Unmap(mv); }
		
		public int Length { get { return _list.Count; } }
		object IArray.this[int index] {  get { return _list[index]; } }		
		//UNO: can't have a second indexer returning T
		public T Get(int index) {  return _list[index]; }
		
		IObservable _observable;
		ISubscription _subscription;
		public void Attach( IObservable obs ) 
		{
			_observable = obs;
			_subscription = _observable.Subscribe(this);
			((IObserver)this).OnNewAll(obs);
		}
		
		public void Detach()
		{
			_list.Clear();
			if (_subscription != null)
			{
				_subscription.Dispose();
				_subscription = null;
			}
			_observable = null;
		}
		
		public void Add( T value )
		{
			_list.Add(value);
			UpdateBacking();
		}
		
		public void RemoveAt( int index )
		{
			_list.RemoveAt(index);
			UpdateBacking();
		}
		
		public void Insert( int index, T value )
		{
			_list.Insert(index, value);
			UpdateBacking();
		}
		
		public void Clear()
		{
			_list.Clear();
			UpdateBacking();
		}
		
		void UpdateBacking()
		{
			if (_subscription == null)
				return;
	
			IArray uv = 	new UnmappedView<T>(this);
			_subscription.ReplaceAllExclusive( uv );	
		}
		
		void IObserver.OnClear()
		{
			_list.Clear();
		}
		
		void IObserver.OnNewAll(IArray values)
		{
			_list.Clear();
			for (int i=0; i < values.Length;  ++i)
				_list.Add( Map(values[i]) );
		}
		
		void IObserver.OnNewAt(int index, object newValue)
		{
			_list[index] = Map(newValue);
		}
		
		void IObserver.OnSet(object newValue)
		{
			_list.Clear();
			_list.Add( Map(newValue) );
		}
		
		void IObserver.OnAdd(object addedValue)
		{
			_list.Add( Map(addedValue) );
		}
		
		void IObserver.OnRemoveAt(int index)
		{
			_list.RemoveAt(index);
		}
		
		void IObserver.OnInsertAt(int index, object value)
		{
			_list.Insert(index, Map(value));
		}
		
		void IObserver.OnFailed(string message)
		{
			_list.Clear();
		}
	}
}
	