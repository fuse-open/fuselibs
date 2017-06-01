using Uno;
using Uno.Collections;

namespace Fuse.Internal
{
	/**
		A list optimized for random insertion/deletion of objects.
		
		The enumeration/iteration of this collection is done in a versioned fashion: the view of the list exposed will be the one at the time the iteration was started. Additions and removals after iteration are started will not change previous views. It is expected that iteration will be short-lived.
		
		It's designed to work around limitations in the Uno memory manager: where assigning/clearing numerous object references can be costly.
	*/
	class ObjectList<T> : IList<T> where T : class
	{
		struct Node
		{
			public T Value;
			
			//link to next node (-1 means none)
			public int Next;
			//link to previous node (-1 means none)
			public int Prev;

			//_lockVersion at a time of addition (until Cleanup)
			public sbyte AddVersion;
			//_lockVersion at time of removal (-1 if not removed)
			public sbyte RemoveVersion;
			
			public void Clear()
			{
				Next = -1;
				Prev = -1;
				AddVersion = (sbyte)0;
				RemoveVersion = (sbyte)-1;
				Value = null;
			}
			
			//the ordered index is piggybacking on the same structure to avoid duplicate memory allocation
			public int Ordered;
		}

		internal const int InitialCapacity = 8;
		
		Node[] _nodes;
		int _capacity = 0;
		int _size = 0;
		//Is the Ordered field up-to-date
		bool _ordered = false;
		
		//if one is -1 they both are
		int _nodeHead = -1;
		int _nodeTail = -1;
		
		//head of the free list, only .Next will be set
		int _free = -1;

		sbyte _lockVersion = 0;
		sbyte _lockCount = 0;

		/** How to compare objects for equality */
		public enum Equality
		{
			Object,
			Value,
		}
		Equality _equality;
		
		public ObjectList(Equality equality = Equality.Object)
		{
			_equality = equality;
			Grow(InitialCapacity);
		}

		public int Count
		{
			get { return _size; }
		}
		
		public void Add(T value)
		{
			int q = AllocNext();
			_ordered = false;
			
			if (_nodeHead == -1)
			{
				_nodes[q].Value = value;
				_nodes[q].AddVersion = _lockVersion;
				_nodeHead = q;
				_nodeTail = q;
				_size++;
				return;
			}
			
			_nodes[_nodeTail].Next = q;
			_nodes[q].Prev = _nodeTail;
			_nodes[q].Value = value;
			_nodes[q].AddVersion = _lockVersion;
			_nodeTail = q;
			_size++;
		}
		
		void Grow(int ncap)
		{
			if (ncap < _capacity +1)
				throw new Exception("invalid Grow");
				
			var next = new Node[ncap];
			for (int i=0; i < _capacity; ++i)
				next[i] = _nodes[i];
			for (int i=_capacity; i < ncap; ++i)
			{
				next[i].Clear();
				next[i].Next = _free;
				_free = i;
			}
			
			if (_free == -1)
				throw new Exception("unexpected _free==-1");
			
			_nodes = next;
			_capacity = ncap;
		}
		
		int AllocNext()
		{
			if (_free == -1)
				Grow(_capacity * 2);
				
			var q = _free;
			_free = _nodes[q].Next;
			_nodes[q].Next = -1;
			return q;
		}
		
		void Unalloc(int q)
		{
			_ordered = false;
			_nodes[q].Clear();
			_nodes[q].Next = _free;
			_free = q;
		}
		
		//creates an ordered list for the nodes so that indexing is fast
		void Order()
		{
			var c = 0;
			var n = _nodeHead;
			while (n != -1)
			{
				_nodes[c].Ordered = n;
				n = _nodes[n].Next;
				c++;
			}
			
			_ordered = true;
		}

		//Used by tests to check if internals of the object are in a consistent state
		internal bool TestIsConsistent
		{
			get
			{
				if (_size < 0 || _size > _capacity)
					return false;
				
				if (CountChain(_nodeHead) != _size)
					return false;
				if (CountChain(_free) != (_capacity - _size))
					return false;
					
				if (_lockVersion != 0)
					return false;
					
				return true;
			}
		}
		
		int CountChain(int q)
		{	
			int c = 0;
			while (q != -1)
			{
				q = _nodes[q].Next;
				c++;
			}
			return c;
		}
		
		public void Insert(int index, T value)
		{
			if (index < 0 || index > _size)
				throw new ArgumentOutOfRangeException(nameof(index));
				
			if (_nodeHead == -1 || index == _size)
			{
				Add(value);
				return;
			}
			
			var cur = NodeAt(index);
			var nu = AllocNext();
			_ordered = false;
			
			var p = _nodes[cur].Prev;
			if (p != -1)
				_nodes[p].Next = nu;
			else
				_nodeHead = nu;
			
			_nodes[cur].Prev = nu;
			
			_nodes[nu].Prev = p;
			_nodes[nu].Next = cur;
			_nodes[nu].Value = value;
			_nodes[nu].AddVersion = _lockVersion;
			_size++;
		}
		
		public bool Remove(T value)
		{
			var q = NodeFor(value);
			if (q == -1)
				return false;
			RemoveNode(q);
			return true;
		}
		
		void RemoveNode(int q)
		{
			if (_lockVersion > 0)
			{
				_nodes[q].RemoveVersion = _lockVersion;
				_ordered = false;
				_size--;
				return;
			}
			
			CollapseNode(q);
			_ordered = false;
			_size--;
		}
		
		void CollapseNode(int q)
		{
			var p = _nodes[q].Prev;
			if (p != -1)
				_nodes[p].Next = _nodes[q].Next;
			else
				_nodeHead = _nodes[q].Next;
				
			var n = _nodes[q].Next;
			if (n != -1)
				_nodes[n].Prev = _nodes[q].Prev;
			else
				_nodeTail = _nodes[q].Prev;
				
			Unalloc(q);
		}
		
		public void RemoveAt(int index)
		{
			RemoveNode(NodeAt(index));
		}

		public void Clear()
		{
			var q = _nodeHead;
			while (q != -1)
			{
				var n = _nodes[q].Next;
				Unalloc(q);
				q = n;
			}
			
			_size = 0;
			_nodeHead = -1;
			_nodeTail = -1;
			_ordered = false;
		}
		
		public bool Contains(T value)
		{
			return NodeFor(value) != -1;
		}

		bool Equals(T a, T b)
		{
			if (_equality == Equality.Object)
				return a == b;
			return Object.Equals(a,b);
		}
		
		int NodeFor(T value)
		{
			var n = _nodeHead;
			while (n != -1)
			{
				if (Equals(_nodes[n].Value, value))
					return n;
				n = _nodes[n].Next;
			}
			
			return -1;
		}
		
		int NodeAt(int index)
		{
			if (index < 0)
				throw new ArgumentOutOfRangeException(nameof(index));
				
			var n = _nodeHead;
			while (n != -1)
			{
				if (_nodes[n].RemoveVersion == -1)
					index--;
					
				if (index < 0)
					break;
					
				n = _nodes[n].Next;
			}
			
			if (n == -1)
				throw new ArgumentOutOfRangeException(nameof(index));
			return n;
		}
		
		public T this[int index]
		{
			get 
			{
				//if something is locked we fallback to the slow mode
				if (_lockVersion > 0)
					return _nodes[NodeAt(index)].Value;
					
 				if (index <0 || index >= _size)
 					throw new ArgumentOutOfRangeException(nameof(index));

				//otherwise we store the ordering and use that.
 				if (!_ordered)
 					Order();
 				return _nodes[_nodes[index].Ordered].Value;
			}
		}
		
		public IEnumerator<T> GetEnumerator()
		{
			return (IEnumerator<T>)new EnumeratorClass(this);
		}
		
		public class EnumeratorClass : IEnumerator<T>
		{
			Enumerator _en;
			
			public EnumeratorClass(ObjectList<T> source)
			{
				_en = new Enumerator(source, false);
			}
			
			public bool MoveNext() { return _en.MoveNext(); }
			public T Current { get { return _en.Current; } }
			public void Reset() { _en.Reset(); }
			public void Dispose() { _en.Dispose(); }
		}
		
		/**
			This iterator can be used only once. It gets a versioned view of the list. It releases that view once the iteration is exhausted or disposed.
			
			This version exists for a few reasons:
			
			- This avoids creating an enumerable and instead used a `struct` that will be copied by value (a memory optimization). The Enumerable is also a struct, and the MS C# compiler can apparently make this optimization implicitly, but the Uno compiler does not recognize this optimization yet.
			- There is a Uno defect https://github.com/fusetools/uno/issues/1148 we therefore can't always just use version locking since we can't rely on `Dispose` being called. Users of this function must explicit use a `using` statement or otherwise call `Dispose`
			
			@param versionLock true to use version locking, false otherwise.
		*/
		internal Enumerator GetEnumeratorStruct(bool versionLock)
		{
			return new Enumerator(this, versionLock);
		}
		
		public Enumerator GetEnumeratorVersionedStruct()
		{
			return GetEnumeratorStruct(true);
		}
		
		public struct Enumerator : IDisposable
		{
			ObjectList<T> _source;
			bool _first;
			int _at;
			sbyte _locked;
			
			public Enumerator(ObjectList<T> source, bool versionLock)
			{
				_source = source;
				_first = true;
				_at = _source._nodeHead;
				_locked = versionLock ? _source.Lock() : (sbyte)-1;
			}
			
			public bool MoveNext()
			{
				if (_first)
					_first = false;
				else
					Next();

				return !Done;	
			}
			
			bool Done
			{
				get 
				{ 
					SkipNew();
					return _at == -1; 
				}
			}
			
			public T Current 
			{
				get 
				{ 
					SkipNew();
					if (_at == -1)
						return null;
						
					return _source._nodes[_at].Value; 
				}
			}
			
			/* Skip any items that should be in this version of the list. When locked this means items removed before the lock, or items added after the lock. When unlocked it means any removed items, but all new items are kept -- unlocked iterates the "Current" version. */
			void SkipNew()
			{
				while (_at != -1)
				{
					var rv = _source._nodes[_at].RemoveVersion;
					if (rv != -1 && (_locked == -1 || rv <= _locked))
					{
						_at = _source._nodes[_at].Next;
						continue;
					}
						
					if (_locked != -1 && _source._nodes[_at].AddVersion > _locked)
					{
						_at = _source._nodes[_at].Next;
						continue;
					}
						
					break;
				}
				
				//once through we unlock it
				if (_at == -1)
					Unlock();
			}
			
			public void Next()
			{
				if (_at != -1)
					_at = _source._nodes[_at].Next;
				SkipNew();
			}
			
			void Unlock()
			{
				if (_locked != -1)
				{
					_locked = (sbyte)-1;
					_source.Unlock();
				}
			}
			
			public void Reset()
			{
				_first = true;
				_at = _source._nodeHead;
			}
			
			public void Dispose()
			{
				Unlock();
				_source = null;
				_at = -1;
			}
		}

		/*
			Locks the list for iteration. 
			
			@return a version that can be used for comparison.
				Items removed after this point will have a RemoveVersion higher than this value.
				Items added after this point will have a AddVersion higher than this value.
		*/
		sbyte Lock()
		{
			if (_lockVersion == 127)
				throw new Exception("excessive iteration starts" );
				
			_lockCount++;
			return _lockVersion++;
		}
		
		/*
			Releases a lock.
			
			Once all locks are released the version on the list will be cleaned and become versionless again.
		*/
		void Unlock()
		{
			_lockCount--;
			if (_lockCount < 0)	
				throw new Exception("invalid call to Unlock");
				
			if (_lockCount == 0)
				CleanupVersion();
		}
		
		void CleanupVersion()
		{
			_lockVersion = 0;
			var n = _nodeHead;
			while (n != -1)
			{
				var p = n;
				n = _nodes[n].Next;

				_nodes[p].AddVersion = 0;
				if (_nodes[p].RemoveVersion != -1)
					CollapseNode(p);
			}
		}
	}
}