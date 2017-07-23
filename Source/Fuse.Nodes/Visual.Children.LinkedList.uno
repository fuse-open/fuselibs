using Uno;
using Uno.Collections;
using Uno.Text;
using Uno.UX;

using Fuse.Internal;

namespace Fuse
{
	public partial class Node
	{
		const int OrphanParentID = -1;
		internal Node _nextSibling;
		internal Node _previousSibling;
		internal int _parentID = OrphanParentID;

		/** Returns the next sibling node of the given type. */
		public T NextSibling<T>() where T: Node
		{ 
			var n = _nextSibling; 
			while (n != null)
			{
				var v = n as T;
				if (v != null) return v;
				n = n._nextSibling;
			}
			return null;
		}

		/** Returns the next sibling node of the given type. */
		public T PreviousSibling<T>() where T: Node 
		{ 
			var n = _previousSibling;
			while (n != null)
			{
				var v = n as T;
				if (v != null) return v;
				n = n._previousSibling;
			}
			return null;
		}
	}

	public partial class Visual
	{
		static int _thisIDEnumerator;
		readonly int _thisID = _thisIDEnumerator++;

		void Children_MakeParent(Visual parent, Node child)
		{
			if (child._parentID != Node.OrphanParentID) throw new Exception();
			child._parentID = parent._thisID;
		}

		void Children_MakeOrphan(Node child)
		{
			child._parentID = Node.OrphanParentID;
		}

		Node _firstChild, _lastChild;
		int _childCount;

		// Internal for now, make public when API matures
		internal int ChildCount { get { return _childCount; } }
		

		void Children_Add(Node n)
		{
			Children_CompleteCurrentAction();
			Children_InvalidateCache();
			Children_MakeParent(this, n);

			if (_firstChild == null) 
			{
				_firstChild = n;
				_lastChild = n;
			}
			else
			{
				_lastChild._nextSibling = n;
				n._previousSibling = _lastChild;
				_lastChild = n;
			}

			_childCount++;
		}

		bool Children_Remove(Node n)
		{
			if (n._parentID != _thisID) return false;

			Children_CompleteCurrentAction();
			Children_InvalidateCache();
			Children_MakeOrphan(n);

			if (_firstChild == n)
			{
				_firstChild = n._nextSibling;
				if (_lastChild == n) _lastChild = null;
			}
			else if (_lastChild == n)
			{
				_lastChild = n._previousSibling;
			}
			else
			{
				n._previousSibling._nextSibling = n._nextSibling;
			}
			n._nextSibling = null;
			n._previousSibling = null;
			_childCount--;
			return true;
		}

		int Children_IndexOf(Node n)
		{
			var k = _firstChild;
			int i = 0;
			while (k != null)
			{
				if (k == n) return i;
				i++;
				k = k._nextSibling;
			}
			return -1;
		}

		Node Children_ItemAt(int index)
		{
			Node k = _firstChild;
			int i = 0;
			while (k != null)
			{
				if (i == index) return k;
				i++;
				k = k._nextSibling;
			}
			throw new IndexOutOfRangeException();
		}

		// Returns the node appropriate to pass to InsertAt(node, elm)
		// if the intention is to Insert(index, elm)
		// This means it returns null if the index == 0, and throws exception
		// if the index was outside bounds
		Node Children_ItemBefore(int index)
		{
			if (index == 0) return null;
			else return Children_ItemAt(index-1);
		}

		void Children_Insert(int index, Node newNode)
		{
			var preceeder = Children_ItemBefore(index);
			Children_InsertAfter(preceeder, newNode);
		}

		void Children_InsertAfter(Node preceeder, Node newNode)
		{
			if (preceeder != null && !Children_Contains(preceeder)) throw new Exception();

			Children_InvalidateCache();
			Children_CompleteCurrentAction();

			if (preceeder == null)
			{
				if (_firstChild == null) Children_Add(newNode);
				else
				{
					Children_MakeParent(this, newNode);
					newNode._nextSibling = _firstChild;
					_firstChild._previousSibling = newNode;
					_firstChild = newNode;
					_childCount++;
				}
			}
			else
			{
				if (_lastChild == preceeder) Children_Add(newNode);
				else
				{
					Children_MakeParent(this, newNode);
					newNode._previousSibling = preceeder;
					newNode._nextSibling = preceeder._nextSibling;
					preceeder._nextSibling._previousSibling = newNode;
					preceeder._nextSibling = newNode;
					_childCount++;
				}
			}

		}

		bool Children_Contains(Node n)
		{
			return n._parentID == _thisID;
		}

		Node Children_CurrentNode;
		Action<Visual, Node> Children_CurrentAction;

		void Children_SafeForEach(Action<Visual, Node> action)
		{
			Children_CompleteCurrentAction();
			Children_CurrentAction = action;
			Children_CurrentNode = _firstChild;
			Children_CompleteCurrentAction();
		}

		void Children_CompleteCurrentAction()
		{
			while (Children_CurrentNode != null)
			{
				Children_CurrentAction(this, Children_CurrentNode);
				Children_CurrentNode = Children_CurrentNode._nextSibling;
			}
			Children_CurrentAction = null;
		}

		Node[] Children_cachedArray;
		Node[] Children_ToArray()
		{
			if (Children_cachedArray != null) return Children_cachedArray;

			var nodes = new Node[_childCount];
			var c = _firstChild;
			int i = 0;
			while (c != null)
			{
				nodes[i] = c;
				c = c._nextSibling;
			}
			Children_cachedArray = nodes;
			return nodes;
		}

		void Children_InvalidateCache()
		{
			Children_cachedArray = null;
		}

		IEnumerator<Node> Children_GetEnumerator()
		{
			return ((IEnumerable<Node>)Children_ToArray()).GetEnumerator();
		}

	}
}