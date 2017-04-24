using Uno;
using Uno.Collections;
using Uno.Threading;

namespace Fuse.Internal
{
	/** Cache the results of a function.

		Also manages the lifetime of the cached results.

		If the number of unused items is greater than maxUnused, this
		class disposes the least recently used unused cached item.
	*/
	public class Cache<TKey, TValue> : IDisposable where TValue : IDisposable
	{
		int _maxUnused;
		readonly LinkedList<CacheRef<TKey, TValue>> _unused = new LinkedList<CacheRef<TKey, TValue>>();
		readonly Dictionary<TKey, CacheRef<TKey, TValue>> _dict = new Dictionary<TKey, CacheRef<TKey, TValue>>();
		readonly Func<TKey, TValue> _factory;
		readonly object _mutex = new object();

		public Cache(Func<TKey, TValue> factory, int maxUnused = 10)
		{
			_factory = factory;
			_maxUnused = maxUnused;
		}

		internal void SignalUnused(CacheRef<TKey, TValue> cacheRef)
		{
			lock (_mutex)
			{
				cacheRef._unusedListNode = _unused.AddLast(cacheRef);

				if (_unused.Count > _maxUnused)
					RemoveUnused(_unused.First);
			}
		}

		internal void SignalUsed(CacheRef<TKey, TValue> cacheRef)
		{
			lock (_mutex)
			{
				_unused.Remove(cacheRef._unusedListNode);
				cacheRef._unusedListNode = null;
			}
		}

		void RemoveUnused(LinkedListNode<CacheRef<TKey, TValue>> node)
		{
			var value = node.Value;
			_unused.Remove(node);
			_dict.Remove(value.Key);
			value.Dispose();
		}

		/** Get or create a cached item.

			Note: CacheItem needs to be disposed when we're done
			with it for it to have a chance to be removed from the
			cache in the future.
		*/
		public CacheItem<TKey, TValue> Get(TKey key)
		{
			lock (_mutex)
			{
				CacheRef<TKey, TValue> cacheRef;
				if (_dict.TryGetValue(key, out cacheRef))
				{
					cacheRef.Retain();
				}
				else
				{
					cacheRef = new CacheRef<TKey, TValue>(this, key, _factory(key));
					_dict.Add(key, cacheRef);
				}
				return new CacheItem<TKey, TValue>(cacheRef);
			}
		}

		/** Disposes all unused items managed by this `Cache`.

			Sets _maxUnused to 0 such that any `CacheItem`s that
			are still alive are disposed immediately when they have
			no references left.
		*/
		public void Dispose()
		{
			lock (_mutex)
			{
				while (_unused.Count > 0)
					RemoveUnused(_unused.First);
				_maxUnused = 0;
			}
		}
	}

	/** A `TValue` whose lifetime is managed by a `Cache`.
	
		`Dispose()` signals to the parent `Cache` that we're no longer
		using `Value`. The `Cache` might subsequently choose to dispose
		`Value`, so we should not rely on `Value` being usable after
		the `CacheItem`'s lifetime.
	*/
	public struct CacheItem<TKey, TValue> : IDisposable where TValue : IDisposable
	{
		readonly CacheRef<TKey, TValue> _cacheRef;

		internal CacheItem(CacheRef<TKey, TValue> cacheRef)
		{
			_cacheRef = cacheRef;
		}

		public TKey Key { get { return _cacheRef.Key; } }
		public TValue Value
		{
			get
			{
				if (_cacheRef._refCount <= 0)
					throw new Exception("Dangling CacheItem");
				return _cacheRef.Value;
			}
		}

		public void Dispose()
		{
			_cacheRef.Release();
		}

		public override int GetHashCode()
		{
			return _cacheRef.GetHashCode();
		}

		public static bool operator==(CacheItem<TKey, TValue> x, CacheItem<TKey, TValue> y)
		{
			return x._cacheRef == y._cacheRef;
		}

		public static bool operator!=(CacheItem<TKey, TValue> x, CacheItem<TKey, TValue> y)
		{
			return x._cacheRef != y._cacheRef;
		}

		public override bool Equals(object o)
		{
			return o.GetType() == typeof(CacheItem<TKey, TValue>)
				? this == (CacheItem<TKey, TValue>)o
				: false;
		}
	}

	class CacheRef<TKey, TValue> : IDisposable where TValue : IDisposable
	{
		readonly Cache<TKey, TValue> _parent;
		public readonly TKey Key;
		public readonly TValue Value;
		internal int _refCount;
		object _refCountMutex = new object();
		internal LinkedListNode<CacheRef<TKey, TValue>> _unusedListNode;

		internal CacheRef<TKey, TValue> _olderUnused;

		internal CacheRef(Cache<TKey, TValue> parent, TKey key, TValue value)
		{
			_parent = parent;
			Key = key;
			Value = value;
			_refCount = 1;
		}

		public void Dispose()
		{
			_unusedListNode = null;
			Value.Dispose();
		}

		public void Retain()
		{
			int refCountBefore = -1;
			lock (_refCountMutex)
			{
				refCountBefore = _refCount;
				++_refCount;
			}
			if (refCountBefore == 0)
				_parent.SignalUsed(this);
		}

		public void Release()
		{
			int refCountAfter = -1;
			lock (_refCountMutex)
			{
				--_refCount;
				refCountAfter = _refCount;
			}
			if (refCountAfter == 0)
				_parent.SignalUnused(this);
		}
	}
}
