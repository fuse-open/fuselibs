using Uno;
using Uno.Collections;
using Uno.Text;
using Uno.UX;

using Fuse.Internal;

namespace Fuse
{
	public partial class Visual
	{
		// Performance critical code paths should not need to create this array.
		// This is here to optimize the corner cases where we need indexed lookup.
		// The SafeIterator also takes advantage of this if available at the time
		// it needs a copy
		Node[] Children_cachedArray;
		Node[] Children_GetCachedArray()
		{
			if (Children_cachedArray != null) return Children_cachedArray;

			var nodes = new Node[_childCount];
			var c = _firstChild;
			int i = 0;
			while (c != null)
			{
				nodes[i++] = c;
				c = c._nextSibling;
			}
			Children_cachedArray = nodes;
			return nodes;
		}

		Node Children_ItemAt(int index)
		{
			var arr = Children_GetCachedArray();
			return arr[index];
		}

		void Children_Invalidate()
		{
			if (_safeIterator != null) _safeIterator.SecureCopy();
			Children_cachedArray = null;
			InvalidateZOrder();
		}

		IEnumerator<Node> Children_GetEnumerator()
		{
			return new SafeIterator(this);
		}

		SafeIterator _safeIterator; // Linked list

		class SafeIterator: IEnumerator<Node>
		{
			Node[] _array;
			int _pos = -1;
			Node _current;
			SafeIterator _nextIterator;
			Visual _v;

			internal SafeIterator(Visual v)
			{
				_v = v;
				AddToIteratorList();
			}

			public Node Current
			{
				get
				{
					if (_array != null) 
					{
						if (_array[_pos] == null) throw new Exception();
						return _array[_pos];
					}
					else 
					{
						if (_current == null) throw new Exception();
						return _current;
					}
				}
			}

			bool _reachedEnd;
			public bool MoveNext()
			{
				if (_reachedEnd) return false;

				if (_pos == -1)
				{
					_array = _v.Children_cachedArray; // If we have a cached array, go ahead and use that
				}

				_pos++;

				if (_array != null)
					return _pos < _array.Length;
				
				if (_current == null) _current = _v._firstChild;
				else _current = _current._nextSibling;

				_reachedEnd = (_current == null);

				return !_reachedEnd;
			}

			public void Dispose()
			{
				Reset();
				RemoveFromIteratorList();
				_v = null;
			}

			public void Reset()
			{
				_pos = -1;
				_current = null;
				_array = null;
				_reachedEnd = false;
			}

			void AddToIteratorList()
			{
				_nextIterator = _v._safeIterator;
				_v._safeIterator = this;
			}

			void RemoveFromIteratorList()
			{
				if (_v._safeIterator == this)
				{
					_v._safeIterator = _nextIterator;
				}
				else
				{
					for (var si = _v._safeIterator; si != null; si = si._nextIterator)
						if (si._nextIterator == this)
						{
							si._nextIterator = this._nextIterator;
							return;
						}
				}
			}

			bool MultipleIterators { get { return _v._safeIterator._nextIterator != null; } }

			internal void SecureCopy()
			{
				if (_array == null)
				{
					if (_v.Children_cachedArray != null || MultipleIterators)
					{
						// If early there are multiple iterators or existing array, get reuse of the array
						_array = _v.Children_GetCachedArray();
					}
					else
					{
						// Otherwise, just copy the remaining items
						_array = new Node[_v._childCount-_pos];
						int i = 0;
						while (_current != null)
						{
							_array[i++] = _current;
							_current = _current._nextSibling;
						}
						// the copied array is just a subset, so reset index
						if (_pos != -1 && _array.Length > 0) _pos = 0; 

						// tempting, but not correct. when _pos != -1, it uses _array[_pos]
						// _current = _array[0]; 
					}
				}

				if (_nextIterator != null) _nextIterator.SecureCopy();

				// We got our copy now, kthxbye
				RemoveFromIteratorList();
			}
		}
	}
}