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
	}
	/*
		Optimized implementation of IList<Node> that creates no extra objects unless needed
	*/
	public partial class Visual
	{
		public bool HasChildren { get { return _children.Count > 0; } }

		protected override void SubtreeToString(StringBuilder sb, int indent)
		{
			base.SubtreeToString(sb, indent);
			for (int i = 0; i < Children.Count; i++)
				Children[i].SubtreeToString(sb, indent+1);
		}

		public T FirstChild<T>() where T: Node
		{
			for (var i = 0; i < Children.Count; ++i)
			{
				var c = Children[i] as T;
				if (c != null)
					return c;
			}
			return null;
		}

		public void RemoveAllChildren<T>()
		{
			var i = Children.Count - 1;
			while (i >= 0)
			{
				if (Children[i] is T)
					Children.RemoveAt(i);

				i = Math.Min(i, Children.Count) - 1;
			}
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
				for (int i = 0; i < Children.Count; i++)
				{
					var n = Children[i];
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
				for (int i = 0; i < Children.Count; i++)
				{
					var n = Children[i];
					var obs = n as IParentObserver;
					if (obs != null && n.IsRootingCompleted) 
						obs.OnChildRemovedWhileRooted(elm);
				}
			}

			if (elm is IParentObserver) _observerCount--;
		}

		MiniList<Node> _children;

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

		void OnVisualAdded(Visual v)
		{
			ZOrder.Insert(0, v);
			InvalidateZOrder();
			InvalidateHitTestBounds();
			InvalidateRenderBounds();
		}

		void OnVisualRemoved(Visual v)
		{
			v.CancelPendingRemove();
			ZOrder.Remove(v);
			InvalidateZOrder();
			InvalidateHitTestBounds();
			InvalidateRenderBounds();
		}

		void ICollection<Node>.Clear()
		{
			foreach (var child in _children)
				OnRemoved(child);
			_children.Clear();
		}

		public void Add(Node item)
		{
			Insert(Children.Count, item);
		}

		public bool Remove(Node item)
		{
			if (_children.Remove(item))
			{
				OnRemoved(item);
				return true;
			}

			return false;
		}

		bool ICollection<Node>.Contains(Node item)
		{
			return _children.Contains(item);
		}

		int ICollection<Node>.Count { get { return _children.Count; } }

		public void Insert(int index, Node item)
		{
			InsertCleanup(item);
			_children.Insert(index, item);
			OnAdded(item);
		}

		void InsertCleanup(Node item)
		{
			var v = item as Visual;
			if (v != null) v.ConcludePendingRemove();
		}

		/**
			Inserts several nodes at the index. This ensures they are all added befor starting 
			any rooting behaviouir, thus guaranteeing they are inerted in consecutive order
			in the Children list (something that calling `Insert` in sequence cannot do, as
			rooting a child could introduce new children).
		*/
		internal void InsertNodes(int index, IEnumerator<Node> items)
		{
			if (index <0 || index > Children.Count)
				throw new ArgumentOutOfRangeException("index");
			
			//cleanup all nodes first
			while (items.MoveNext())
				InsertCleanup( items.Current );

			//nodes should be considered added in the same group
			var capture = CaptureRooting();
			try
			{
				//then add all
				items.Reset();
				while (items.MoveNext())
					_children.Insert(index++, items.Current);

				//then process them
				items.Reset();
				while (items.MoveNext())
					OnAdded(items.Current);
			}
			finally
			{
				ReleaseRooting(capture);
			}
		}

		void IList<Node>.RemoveAt(int index)
		{
			var b = _children[index];
			_children.RemoveAt(index);
			OnRemoved(b);
		}

		Node IList<Node>.this[int index] { get { return _children[index]; } }

		IEnumerator<Node> IEnumerable<Node>.GetEnumerator() { return _children.GetEnumerator(); }
	}
}
