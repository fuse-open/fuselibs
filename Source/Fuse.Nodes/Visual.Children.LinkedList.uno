using Uno;
using Uno.Collections;
using Uno.Text;
using Uno.UX;

using Fuse.Internal;

namespace Fuse
{
	public partial class Node
	{
		internal Node Children_next;
		internal Node Children_previous;
		internal int Children_parentID = -1;
	}

	public partial class Visual
	{
		static int Children_thisIDEnumerator;
		readonly int Children_thisID = Children_thisIDEnumerator++;

		void Children_MakeParent(Visual parent, Node child)
		{
			if (child.Children_parentID != -1) throw new Exception();
			child.Children_parentID = parent.Children_thisID;
		}

		void Children_MakeOrphan(Node child)
		{
			child.Children_parentID = -1;
		}

		internal Node Children_first;
		internal Node Children_last;
		int Children_count;

		void Children_Add(Node n)
		{
			Children_CompleteCurrentAction();
			Children_InvalidateCache();
			Children_MakeParent(this, n);

			if (Children_first == null) 
			{
				Children_first = n;
				Children_last = n;
			}
			else
			{
				Children_last.Children_next = n;
				n.Children_previous = Children_last;
				Children_last = n;
			}

			Children_count++;
		}

		bool Children_Remove(Node n)
		{
			if (n.Children_parentID != Children_thisID) return false;

			Children_CompleteCurrentAction();
			Children_InvalidateCache();
			Children_MakeOrphan(n);

			if (Children_first == n)
			{
				Children_first = n.Children_next;
				if (Children_last == n) Children_last = null;
			}
			else if (Children_last == n)
			{
				Children_last = n.Children_previous;
			}
			else
			{
				n.Children_previous.Children_next = n.Children_next;
			}
			n.Children_next = null;
			n.Children_previous = null;
			Children_count--;
			return true;
		}

		int Children_IndexOf(Node n)
		{
			var k = Children_first;
			int i = 0;
			while (k != null)
			{
				if (k == n) return i;
				i++;
				k = k.Children_next;
			}
			return -1;
		}

		Node Children_ItemAt(int index)
		{
			Node k = Children_first;
			int i = 0;
			while (k != null)
			{
				if (i == index) return k;
				i++;
				k = k.Children_next;
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
				if (Children_first == null) Children_Add(newNode);
				else
				{
					Children_MakeParent(this, newNode);
					newNode.Children_next = Children_first;
					Children_first.Children_previous = newNode;
					Children_first = newNode;
					Children_count++;
				}
			}
			else
			{
				if (Children_last == preceeder) Children_Add(newNode);
				else
				{
					Children_MakeParent(this, newNode);
					newNode.Children_previous = preceeder;
					newNode.Children_next = preceeder.Children_next;
					preceeder.Children_next.Children_previous = newNode;
					preceeder.Children_next = newNode;
					Children_count++;
				}
			}

		}

		bool Children_Contains(Node n)
		{
			return n.Children_parentID == Children_thisID;
		}

		Node Children_CurrentNode;
		Action<Visual, Node> Children_CurrentAction;

		void Children_SafeForEach(Action<Visual, Node> action)
		{
			Children_CompleteCurrentAction();
			Children_CurrentAction = action;
			Children_CurrentNode = Children_first;
			Children_CompleteCurrentAction();
		}

		void Children_CompleteCurrentAction()
		{
			while (Children_CurrentNode != null)
			{
				Children_CurrentAction(this, Children_CurrentNode);
				Children_CurrentNode = Children_CurrentNode.Children_next;
			}
			Children_CurrentAction = null;
		}

		Node[] Children_cachedArray;
		Node[] Children_ToArray()
		{
			if (Children_cachedArray != null) return Children_cachedArray;

			var nodes = new Node[Children_count];
			var c = Children_first;
			int i = 0;
			while (c != null)
			{
				nodes[i] = c;
				c = c.Children_next;
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