using Uno;
using Uno.Collections;
using Uno.Text;
using Uno.UX;

using Fuse.Internal;

namespace Fuse
{
	public partial class Node
	{
		internal const int OrphanParentID = -1;
		internal Node _nextSibling;
		
		internal int _parentID = OrphanParentID;

		// Using Fuse.Internal.RawPointer<T> to avoid reference loop
		// use this field with special caution!
		internal RawPointer<Node> _previousSibling;


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
			var n = (Node)_previousSibling;
			while (n != null)
			{
				var v = n as T;
				if (v != null) return v;
				n = (Node)n._previousSibling;
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
			if (child._parentID != Node.OrphanParentID) throw new Exception("Node already has a parent - can only have one");
			child._parentID = parent._thisID;
		}

		void Children_MakeOrphan(Node child)
		{
			child._parentID = Node.OrphanParentID;
		}

		Node _firstChild, _lastChild;
		int _childCount;
		int _visualChildCount;

		/** The number of child nodes of this visual. */
		public int ChildCount { get { return _childCount; } }

		/** The number of child visuals of this visual. */
		public int VisualChildCount { get { return _visualChildCount; } }
		
		void Children_Clear()
		{
			Children_Invalidate();
			
			for (var c = _firstChild; c != null; c = c._nextSibling)
			{
				Children_MakeOrphan(c);
				c._nextSibling = null;
				c._previousSibling = (Node)null;
			}
			
			_firstChild = null;
			_lastChild = null;
			_childCount = 0;
			_visualChildCount = 0;
		}

		void Children_Add(Node n)
		{
			Children_Invalidate();
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
			if (n is Visual) _visualChildCount++;
		}

		bool Children_Remove(Node n)
		{
			if (n._parentID != _thisID) return false;

			Children_Invalidate();
			Children_MakeOrphan(n);

			if (_firstChild == n)
			{
				_firstChild = n._nextSibling;
				if (_firstChild != null) _firstChild._previousSibling = (Node)null;
				if (_lastChild == n) _lastChild = null;
			}
			else if (_lastChild == n)
			{
				_lastChild = (Node)n._previousSibling;
				if (_lastChild != null) _lastChild._nextSibling = null;
			}
			else
			{
				((Node)n._previousSibling)._nextSibling = n._nextSibling;
				n._nextSibling._previousSibling = (Node)n._previousSibling;
			}
			n._nextSibling = null;
			n._previousSibling = (Node)null;
			_childCount--;
			if (n is Visual) _visualChildCount--;
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

			Children_Invalidate();

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
					if (newNode is Visual) _visualChildCount++;
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
					if (newNode is Visual) _visualChildCount++;
				}
			}

		}

		bool Children_Contains(Node n)
		{
			return n._parentID == _thisID;
		}

	}
}