using Uno;

namespace Fuse
{
	public sealed class PendingRemoveVisual : IUpdateListener
	{
		public Visual Parent { get; private set; }
		public Visual Child { get; private set; }

		Action<Node> _then;

		internal PendingRemoveVisual(Visual child, Visual parent, Action<Node> then)
		{
			Parent = parent;
			Child = child;
			_then = then;
		}

		int subscribers = 0;
		public void AddSubscriber()
		{
			subscribers++;
		}

		public void RemoveSubscriber()
		{
			subscribers--;
			if (subscribers == 0)
			{
				Remove();
			}
		}

		public bool HasSubscribers
		{
			get { return subscribers > 0; }
		}

		bool _done;
		public void Remove()
		{
			if (_done)
				return;
			
			if (_then != null) _then(Child);
			_done = true;
			Child.ConcludePendingRemove();
		}
		
		void IUpdateListener.Update()
		{
			Remove();
		}
	}
	
	public interface IBeginRemoveVisualListener
	{
		void OnBeginRemoveVisual(PendingRemoveVisual pr);
	}

	public partial class Visual
	{
		/** Begins removing a given visual, playing all @RemovedAnimations before actual removal. */
		public void BeginRemoveVisual(Visual child, Action<Node> then = null)
		{
			if (!IsRootingCompleted)
			{
				Children.Remove(child);
				if (then != null) then(child);
				return;
			}
			
			if (!Children.Contains(child))
				return;
				
			//refer to the issue, this needs to be fixed better
			//https://github.com/fusetools/fuselibs-private/issues/1966
			if (child.HasBit(FastProperty1.PendingRemove))
				return;
			
			var args = new PendingRemoveVisual(child, this, then);

			child.OnBeginRemoveVisual(args);

			if (args.HasSubscribers)
			{
				InvalidateLayout();
			}
			else
			{
				UpdateManager.AddDeferredAction(args);
			}
		}

		/** Begins removing a given node, playing all @RemovedAnimations before actual removal. */
		public void BeginRemoveChild(Node n, Action<Node> then = null)
		{
			var v = n as Visual;
			if (v != null) BeginRemoveVisual(v, then);
			else 
			{
				Children.Remove(n);
				if (then != null) then(n);
			}
		}
		
		protected void OnBeginRemoveVisual(PendingRemoveVisual args)
		{
			SetBit(FastProperty1.PendingRemove, true);

			for (var n = FirstChild<Node>(); n != null; n = n.NextSibling<Node>())
			{
				var rvl = n as IBeginRemoveVisualListener;
				if (rvl != null) rvl.OnBeginRemoveVisual(args);
			}
		}

		internal void CancelPendingRemove()
		{
			if (HasBit(FastProperty1.PendingRemove))
			{
				SetBit(FastProperty1.PendingRemove, false);
			}
		}

		internal void ConcludePendingRemove()
		{
			if (HasBit(FastProperty1.PendingRemove))
			{
				Parent.Children.Remove(this);
				SetBit(FastProperty1.PendingRemove, false);
			}
		}

		public bool HasPendingRemove { get { return HasBit(FastProperty1.PendingRemove); } }
	}
}
