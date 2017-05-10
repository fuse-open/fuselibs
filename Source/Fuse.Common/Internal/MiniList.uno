using Uno;
using Uno.Collections;

namespace Fuse.Internal
{
	/**
		A simple list that reduces overhead for objects where 0 or 1 items is far more common than 2+.

		This does not support `null` items.
	*/
	struct MiniList<T> : IList<T> where T : class
	{
		object _list;

		public int Count
		{
			get
			{
				var list = _list as List<T>;
				if (list != null)
					return list.Count;
					
				return _list == null ? 0 : 1;
			}
		}

		public void Add(T value)
		{
			Insert(Count, value);
		}

		public void Insert(int index, T value)
		{
			if (value == null)
				throw new ArgumentNullException(nameof(value));

			var list = _list as List<T>;
			if (list == null)
			{
				if (_list == null && index != 0)
					throw new ArgumentOutOfRangeException(nameof(index));
					
				list = new List<T>();
				if (_list != null)
					list.Add(_list as T);
				_list = list;
			}
			list.Insert(index, value);
		}

		public bool Remove(T value)
		{
			if (_list != null && Object.Equals(_list, value))
			{
				_list = null;
				return true;
			}

			var list = _list as List<T>;
			if (list == null)
				return false;

			return list.Remove(value);
		}

		public void RemoveAt(int index)
		{
			var list = _list as List<T>;
			if (list != null)
			{
				list.RemoveAt(index);
				return;
			}
			
			if (index != 0)
				throw new ArgumentOutOfRangeException(nameof(index));

			_list = null;
		}

		public void Clear()
		{
			var list = _list as List<T>;
			if (list != null)
				list.Clear();
			else
				_list = null;
		}

		public bool Contains(T value)
		{
			var list = _list as List<T>;
			if (list != null)
				return list.Contains(value);
				
			return _list != null && Object.Equals(_list, value);
		}

		public T this[int index]
		{
			get
			{
				var list = _list as List<T>;
				if (list != null)
					return list[index];
					
				if (index != 0)
					throw new IndexOutOfRangeException();

				return _list as T;
			}
		}

		public IEnumerator<T> GetEnumerator()
		{
			return (IEnumerator<T>)new Enumerator<T>(this);
		}

		struct Enumerator<T> : IEnumerator<T> where T : class
		{
			MiniList<T> _source;
			int _index;

			public Enumerator(MiniList<T> source)
			{
				_source = source;
				_index = -1;
			}

			public bool MoveNext()
			{
				return ++_index < _source.Count;
			}

			public T Current { get { return _source[_index]; } }

			public void Reset()
			{
				_index = -1;
			}

			public void Dispose() { }
		}
	}
}
