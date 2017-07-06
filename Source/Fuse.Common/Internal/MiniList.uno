using Uno;
using Uno.Collections;

namespace Fuse.Internal
{
	//An error with Uno handling the Enumerator<T> generic is preventing this from being a private enum to MiniList
	//E2047: No implicit cast from Fuse.Internal.MiniList<T>.Mode to Fuse.Internal.MiniList<T>.Mode
	//UNO: https://github.com/fusetools/uno/issues/1172
	enum MiniListMode
	{
		Empty,
		Single,
		List,
	}
	
	/**
		A list that reduces allocation overhead for places where 0 or 1 items is far more common than 2+. 0 and 1 item can be stored with zero allocations on the containing class -- note that `MiniList` is a `struct` type.

		This does not support `null` items.
		
		This is backed by an `ObjectList` for 2+ items. This provides the same ability to do versioned iteration without needing a copy of the list.
		
		WARNING: Be careful using the `IList` interface. You only use it in certain generic functions and in `using` statements. Otherwise you will end up creating a boxed copy.
	*/
	struct MiniList<T> : IList<T> where T : class
	{
		object _list;
		ObjectList<T> AsList { get { return (ObjectList<T>)_list; } }
		
		//The current mode is tracked explicitly to avoid some overhead of dynamically checking the type of `_list`.
		MiniListMode _mode = MiniListMode.Empty;

		public int Count
		{
			get
			{
				switch (_mode)
				{
					case MiniListMode.Empty: 
						return 0;
					case MiniListMode.Single:
						return 1;
					case MiniListMode.List:
						return AsList.Count;
				}

				//unreachable
				return 0;
			}
		}

		public void Add(T value)
		{
			Insert(Count, value);
		}

		public void Insert(int index, T value)
		{
			//TODO: we could lift this restriction now
			if (value == null)
				throw new ArgumentNullException(nameof(value));

			if (_mode == MiniListMode.Empty)
			{
				if (index != 0)
					throw new ArgumentOutOfRangeException(nameof(index));
				_list = value;
				_mode = MiniListMode.Single;
				return;
			}
			
			if (_mode == MiniListMode.Single)
			{
				//OPT: Since we primarily use this for items that don't require Value equality we
				//should consider changing this, or making it configurable.
				var l = new ObjectList<T>(ObjectList<T>.Equality.Value);
				l.Add(_list as T);
				_list = l;
				_mode = MiniListMode.List;
			}
			
			AsList.Insert(index, value);
		}

		public bool Remove(T value)
		{
			if (_mode == MiniListMode.Empty)
				return false;
				
			if (_mode == MiniListMode.Single)
			{
				if (!Object.Equals(_list, value))
					return false;
			
				_list = null;
				_mode = MiniListMode.Empty;
				return true;
			}

			return AsList.Remove(value);
		}

		public void RemoveAt(int index)
		{
			if (_mode == MiniListMode.Empty)
				throw new ArgumentOutOfRangeException(nameof(index));
				
			if (_mode == MiniListMode.Single)
			{
				if (index != 0)
					throw new ArgumentOutOfRangeException(nameof(index));
				_mode = MiniListMode.Empty;
				_list = null;
				return;
			}
			
			AsList.RemoveAt(index);
		}

		public void Clear()
		{
			switch (_mode)
			{
				case MiniListMode.Empty:
					break;
					
				case MiniListMode.Single:
					_list = null;
					_mode = MiniListMode.Empty;
					break;
					
				case MiniListMode.List:
					AsList.Clear();
					break;
			}
		}

		public bool Contains(T value)
		{
			switch (_mode)
			{
				case MiniListMode.Empty:
					return false;
					
				case MiniListMode.Single:
					return Object.Equals(_list, value);
					
				case MiniListMode.List:
					return AsList.Contains(value);
			}
			
			//unreachable
			return false;
		}

		public T this[int index]
		{
			get
			{
				switch (_mode)
				{
					case MiniListMode.Empty:
						throw new IndexOutOfRangeException();
						
					case MiniListMode.Single:
						if (index != 0)
							throw new IndexOutOfRangeException();
						return _list as T;
						
					case MiniListMode.List:
						return AsList[index];
				}
				
				//unreachable
				return null;
			}
		}

		public IEnumerator<T> GetEnumerator()
		{
			return (IEnumerator<T>)new Enumerator(this, false);
		}

		public Enumerator GetEnumeratorVersionedStruct()
		{
			return new Enumerator(this, true);
		}
		
		public struct Enumerator : IEnumerator<T>
		{
			ObjectList<T>.Enumerator _iter;
			MiniList<T> _source;
			bool _first;
			Object _value;
			MiniListMode _mode;
			
			public Enumerator(MiniList<T> source, bool versionLock)
			{
				_mode = source._mode;
				if (_mode == MiniListMode.List)
					_iter = source.AsList.GetEnumeratorStruct(versionLock);
				else
					_value = source._list;
				_source = source;
				_first = true;
			}
			
			public T Current
			{
				get
				{
					switch (_mode)
					{
						case MiniListMode.Empty:
							return null;
						
						case MiniListMode.Single:
							return _value as T;
							
						case MiniListMode.List:
							return _iter.Current;
					}
					
					return null;
				}
			}
			
			
			public void Dispose()
			{
				if (_mode == MiniListMode.List)
					_iter.Dispose();
				_mode = MiniListMode.Empty;
				_value = null;
			}
			
			public bool MoveNext()
			{
				switch (_mode)
				{
					case MiniListMode.Empty:
						_first = false;
						return false;
						
					case MiniListMode.Single:
						if (_first)
						{
							_first = false;
							return true;
						}
						return false;
						
					case MiniListMode.List:
						return _iter.MoveNext();
				}
				
				return false;	
			}

			public void Reset()
			{
				_first = true;
				if (_mode == MiniListMode.List)
					_iter.Reset();
			}
		}
	}
}
