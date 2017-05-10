using Uno;

namespace Uno.Collections
{
	struct PriorityQueueItem<T>
	{
		public T Value;
		public float4 Priority;
	}
	
	enum PriorityQueueType
	{
		/** If items have matching priority the earlier ones will be popped first */
		Fifo,
		/** If items have matching priority the later ones will be popped first */
		Lifo,
	}
	
	/**
		Items in a priority queue are stored in priority order, with lower value priority coming
		earlier in the list.
	*/
	class PriorityQueue<T>
	{
		List<PriorityQueueItem<T>> _items = new List<PriorityQueueItem<T>>();
		
		PriorityQueueType _type;
		public PriorityQueue(PriorityQueueType type = PriorityQueueType.Fifo)
		{
			_type = type;
		}
		
		static int Compare(float4 a, float4 b)
		{
			for (int i=0; i < 4; ++i)
			{
				if (a[i] < b[i])
					return -1;
				if (a[i] > b[i])
					return 1;
			}
			return 0;
		}
		
		/**
			Returns the index of the first item that does not go before the given priority.
		*/
		int LowerBound(float4 priority)
		{
			//OPT: use a BinarySearch if this becomes troublesome
			for (int i=0; i < _items.Count; ++i)
				if (Compare(_items[i].Priority,priority) >= 0)
					return i;
			return _items.Count;
		}
		
		/**
			Returns the index of the first item that goes after the given priority.
		*/
		int UpperBound(float4 priority)
		{
			//OPT: use a BinarySearch if this becomes troublesome
			for (int i=0; i < _items.Count; ++i)
				if (Compare(_items[i].Priority,priority) > 0)
					return i;
			return _items.Count;
		}
		
		public void Add(T value, float priority) { Add( value, float4(priority,0,0,0) ); }
		public void Add(T value, float2 priority) { Add( value, float4(priority,0,0) ); }
		public void Add(T value, float3 priority) { Add( value, float4(priority,0) ); }
		
		public void Add(T value, float4 priority)
		{
			int at = (_type == PriorityQueueType.Fifo) ? LowerBound(priority) : UpperBound(priority);
			_items.Insert(at, new PriorityQueueItem<T> { Value = value, Priority = priority });
		}

		public void Add(T value) { Add( value, float4(0) ); }
		
		public void Remove(T value)
		{
			for (int i=0; i < _items.Count; ++i)
			{
				if (object.Equals(_items[i].Value,value))
				{
					_items.RemoveAt(i);
					break;
				}
			}
		}
		
		public T PopTop()
		{
			float4 ignore;
			return PopTop( out ignore );
		}
		
		public T PopTop( out float4 priority )
		{
			int i = _items.Count - 1;
			var v = _items[i].Value;
			priority = _items[i].Priority;
			_items.RemoveAt(i);
			return v;
		}
		
		public bool Empty
		{
			get { return _items.Count == 0; }
		}
		
		public int Count
		{
			get { return _items.Count; }
		}
		
		public T this [int index]
		{
			get { return _items[index].Value; }
		}
	}
}
