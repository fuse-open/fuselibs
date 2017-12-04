using Uno;
using Uno.Collections;

namespace Uno.Collections
{
	/**
		 A list that can be subscribed to during rooting to observe for changes.
		 
		 @advanced
		 @experimental
	*/
	public class RootableList<T>: IList<T>
	{
		List<T> _items = null;

		Action<T> _added, _removed;

		public void Subscribe(Action<T> added, Action<T> removed)
		{
			if (this._added != null)
				throw new Exception( "Supports only one subscription" );
				
			if (added == null)
				throw new ArgumentNullException(nameof(added));
			if (removed == null)
				throw new ArgumentNullException(nameof(removed));

			_added = added;
			_removed = removed;
		}
		
		public void RootSubscribe(Action<T> added, Action<T> removed)
		{
			Subscribe(added, removed);
			if (_items == null)
				return;
				
			for (int i=0; i < _items.Count; ++i)
				OnAdded(_items[i]);
		}
		
		public void Unsubscribe()
		{
			_added = null;
			_removed = null;
		}
		
		public void RootUnsubscribe()
		{
			var removed = _removed;
			Unsubscribe();
			
			if (removed != null && _items != null)
			{
				for (int i=0; i < _items.Count; ++i)
					removed(_items[i]);
			}
		}

		void OnAdded(T item)
		{
			if (_added != null)
				_added(item);
		}
		
		void OnRemoved(T item)
		{
			if (_removed != null)
				_removed(item);
		}
		
		public void Clear()
		{
			if (_items != null)
			{
				var removedItems = _items;
				_items = null;
				foreach (var i in removedItems)
					OnRemoved(i);
			}
		}

		public bool Contains(T item)
		{
			if (_items == null)
				return false;

			return _items.Contains(item);
		}

		public void Add(T item)
		{
			if (_items == null)
				_items = new List<T>();

			_items.Add(item);
			OnAdded(item);
		}

		public void Insert(int index, T item)
		{
			if (_items == null)
				_items = new List<T>();

			_items.Insert(index, item);
			OnAdded(item);
		}
		
		public void ReplaceAt(int index, T item)
		{
			if (_items == null)
				throw new IndexOutOfRangeException();
				
			var old = _items[index];
			_items[index] = item;
			OnRemoved(old);
			OnAdded(item);
		}

		public void RemoveAt(int index)
		{
			if (_items == null)
				throw new IndexOutOfRangeException();

			Remove(_items[index]);
		}

		public bool Remove(T item)
		{
			if (_items == null)
				return false;

			var res = _items.Remove(item);
			if (res)
				OnRemoved(item);
			return res;
		}

		public int Count { get { return _items != null ? _items.Count : 0; } }

		public T this [int index]
		{
			get
			{
				if (_items == null)
					throw new IndexOutOfRangeException();

				return _items[index];
			}
		}

		public IEnumerator<T> GetEnumerator()
		{
			if (_items == null)
				_items = new List<T>();

			return _items.GetEnumerator();
		}
	}
}
