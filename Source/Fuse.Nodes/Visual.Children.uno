using Uno;
using Uno.Collections;
using Uno.Text;
using Uno.UX;

using Fuse.Internal;

namespace Fuse
{
	public interface IParentObserver
	{
		void OnChildAddedWhileRooted(Node n);
		void OnChildRemovedWhileRooted(Node n);
		void OnChildMovedWhileRooted(Node n);
	}
	/*
		Optimized implementation of IList<Node> that creates no extra objects unless needed
	*/
	public partial class Visual
	{
		public bool HasChildren { get { return ChildCount > 0; } }

		protected override void SubtreeToString(StringBuilder sb, int indent)
		{
			base.SubtreeToString(sb, indent);
			for (var c = FirstChild<Node>(); c != null; c = c.NextSibling<Node>())
				c.SubtreeToString(sb, indent+1);
		}

		/** Returns the first child node of the given type. 
			
			To get the very first child node (of any type), use `FirstChild<Node>()`.
		*/
		public T FirstChild<T>() where T: Node
		{
			var c = _firstChild;
			while (c != null)
			{
				var v = c as T;
				if (v != null) return v;
				c = c._nextSibling;
			}
			return null;
		}

		/** Returns the last child node of the given type. 

			To get the very last child node (of any type), use `LastChild<Node>()`.
		*/
		public T LastChild<T>() where T: Node
		{
			var c = _lastChild;
			while (c != null)
			{
				var v = c as T;
				if (v != null) return v;
				c = (Node)c._previousSibling;
			}
			return null;
		}

		/** Removes all children of the given type. 
			
			To remove all children (of all types), use `RemoveAllChildren<Node>()`.
		*/
		public void RemoveAllChildren<T>() where T: Node
		{
			// Has to use use safe iterator, ref discussion on https://github.com/fusetools/fuselibs-public/pull/260
			foreach (var c in Children) 
				if (c is T) Children_Remove(c);
		}

		[UXPrimary]
		/** The children of the visual.
			All nodes placed inside the visual in UX markup are assigned to this list.
			The order of @Visuals this list determines the order of layout. The Z-order
			of the children is by default equal to this order, but can be manipulated
			separately using methods like @BringToFront and @SendToBack.
		*/
		public IList<Node> Children { get { return this; } }

		// TODO: rewrite to HasObservers bit
		int _observerCount;

		protected virtual void OnChildAdded(Node elm)
		{
			if (_observerCount != 0 && IsRootingStarted)
			{
				for (var n = FirstChild<Node>(); n != null; n = n.NextSibling<Node>())
				{
					var obs = n as IParentObserver;
					if (obs != null && n.IsRootingCompleted)
						obs.OnChildAddedWhileRooted(elm);
				}
			}

			if (elm is IParentObserver) _observerCount++;
		}

		protected virtual void OnChildRemoved(Node elm)
		{
			if (_observerCount != 0 && IsRootingStarted)
			{
				for (var n = FirstChild<Node>(); n != null; n = n.NextSibling<Node>())
				{
					var obs = n as IParentObserver;
					if (obs != null && n.IsRootingCompleted) 
						obs.OnChildRemovedWhileRooted(elm);
				}
			}

			if (elm is IParentObserver) _observerCount--;
		}

		protected virtual void OnChildMoved(Node elm)
		{
			if (_observerCount != 0 && IsRootingStarted)
			{
				for (var n = FirstChild<Node>(); n != null; n = n.NextSibling<Node>())
				{
					var obs = n as IParentObserver;
					if (obs != null && n.IsRootingCompleted) 
						obs.OnChildMovedWhileRooted(elm);
				}
			}
		}
		
		void OnAdded(Node b)
		{
			var v = b as Visual;
			if (v != null) OnVisualAdded(v);

			var t = b as Transform;
			if (t != null) OnTransformAdded(t);

			Relate(this, b);
			OnChildAdded(b);
		}

		void OnRemoved(Node b)
		{
			var v = b as Visual;
			if (v != null) OnVisualRemoved(v);

			var t = b as Transform;
			if (t != null) OnTransformRemoved(t);

			Unrelate(this, b);
			OnChildRemoved(b);
		}
		
		void OnMoved(Node b)
		{
			OnChildMoved(b);
		}

		void OnVisualAdded(Visual v)
		{
			InvalidateHitTestBounds();
			InvalidateRenderBounds();
		}

		void OnVisualRemoved(Visual v)
		{
			v.CancelPendingRemove();
			InvalidateHitTestBounds();
			InvalidateRenderBounds();
		}
		
		void ICollection<Node>.Clear()
		{
			for (var c = _firstChild; c != null; c = c._nextSibling)
				OnRemoved(c);
			Children_Clear();
		}

		public void Add(Node item)
		{
			InsertCleanup(item);
			Children_Add(item);
			OnAdded(item);
		}

		public bool Remove(Node item)
		{
			if (Children_Remove(item))
			{
				OnRemoved(item);
				return true;
			}

			return false;
		}

		/** Inserts a child node after the given sibling node.
			
			For performance reasons, this entrypoint is recommended over using `InsertAt`.

			To insert at the beginning of the list, use `null` as the first argument.
		*/
		public void InsertAfter(Node sibling, Node node)
		{
			InsertCleanup(node);
			Children_InsertAfter(sibling, node);
			OnAdded(node);
		}

		bool ICollection<Node>.Contains(Node item)
		{
			return Children_Contains(item);
		}
		
		int IndexOf(Node item)
		{
			return Children_IndexOf(item);
		}

		int ICollection<Node>.Count { get { return ChildCount; } }

		public void Insert(int index, Node item)
		{
			InsertCleanup(item);
			Children_Insert(index, item);
			OnAdded(item);
		}

		void InsertCleanup(Node item)
		{
			var v = item as Visual;
			if (v != null) v.ConcludePendingRemove();
		}

		/**
			Inserts several nodes at the location. This ensures they are all added befor starting 
			any rooting behaviouir, thus guaranteeing they are inerted in consecutive order
			in the Children list (something that calling `Insert` in sequence cannot do, as
			rooting a child could introduce new children).
		*/
		internal void InsertNodesAfter(Node preceeder, IEnumerator<Node> items)
		{
			InsertNodesAfterImpl(preceeder, items, false);
		}

		internal void InsertOrMoveNodesAfter(Node preceeder, IEnumerator<Node> items)
		{
			InsertNodesAfterImpl(preceeder, items, true);
		}
		
		
		void InsertNodesAfterImpl(Node preceeder, IEnumerator<Node> items, bool allowMove)
		{
			if (!Children_Contains(preceeder)) 
				throw new Exception("Cannot insert nodes after a node that is not a child of this parent");

			//cleanup all nodes first
			while (items.MoveNext())
				InsertCleanup( items.Current );

			//becomes non-null on the first moved node
			HashSet<Node> moved = null;
			
			//nodes should be considered added in the same group
			var capture = CaptureRooting();
			try
			{
				//then add all
				items.Reset();
				while (items.MoveNext())
				{
					var c = items.Current;
					if (allowMove)
					{
						if (Children_Contains(c))
						{
							Children_Remove(c);
							if (moved == null)
								moved = new HashSet<Node>();
							moved.Add(c);
						}
					}
					Children_InsertAfter(preceeder, c);
					preceeder = c;
				}

				//then process them
				items.Reset();
				while (items.MoveNext())
				{
					var c = items.Current;
					if (moved == null || !moved.Contains(c))
						OnAdded(c);
					else
						OnMoved(c);
				}
			}
			finally
			{
				ReleaseRooting(capture);
			}
		}

		void IList<Node>.RemoveAt(int index)
		{
			var b = Children[index];
			Children_Remove(b);
			OnRemoved(b);
		}

		Node IList<Node>.this[int index] { get { return Children_ItemAt(index); } }

		IEnumerator<Node> IEnumerable<Node>.GetEnumerator() { return Children_GetEnumerator(); }
	}
}
