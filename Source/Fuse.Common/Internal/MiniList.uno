using Uno;
using Uno.Collections;

namespace Fuse.Internal
{
	//An error with Uno handling the Enumerator<T> generic is preventing this from being a private enum to MiniList
	//E2047: No implicit cast from Fuse.Internal.MiniList<T>.Mode to Fuse.Internal.MiniList<T>.Mode
	enum MiniListMode
	{
		Empty,
		Single,
		List,
	}
	
	/**
		A simple list that reduces overhead for objects where 0 or 1 items is far more common than 2+.

		This does not support `null` items.
	*/
	struct MiniList<T> : IList<T> where T : class
	{
		object _list;
		ObjectList<T> AsList { get { return (ObjectList<T>)_list; } }
		
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
			return (IEnumerator<T>)new Enumerator<T>(this);
		}

		public Enumerator<T> GetEnumeratorStruct()
		{
			return new Enumerator<T>(this);
		}
		
		public struct Enumerator<T> : IEnumerator<T> where T : class
		{
			ObjectList<T>.Enumerator<T> _iter;
			MiniList<T> _source;
			bool _first;
			Object _value;
			MiniListMode _mode;
			
			public Enumerator(MiniList<T> source)
			{
				_mode = source._mode;
				if (_mode == MiniListMode.List)
					_iter = source.AsList.GetEnumeratorStruct();
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
						_mode = MiniListMode.Empty;
						return false;
						
					case MiniListMode.List:
						return _iter.MoveNext();
				}
				
				return false;	
			}

			public void Reset()
			{
				//it's easier not to support this since it would invovle tracking the initial iterator state (added overhead)
				//or it would incorrectly iterate the current source, not the one at the time of creation
				throw new Exception( "Reset not supported" );
			}
		}
	}
}
