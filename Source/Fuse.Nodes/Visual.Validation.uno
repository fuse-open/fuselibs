
namespace Fuse
{
	public partial class Visual
	{
		int _lastInvalidate = -1;

		/**
			Indicates the visual for this node has changed. This allows the root-level node to know
			that it must draw, and any caching that it must invalidate the cache for this node.
		*/
		public void InvalidateVisual()
		{
			if (_lastInvalidate == UpdateManager.FrameIndex)
				return;
			_lastInvalidate = UpdateManager.FrameIndex;
			OnInvalidateVisual();

			//invisible items don't propagate, but in `OnIsVisibelChanged` invalidation to parent is done
			if (Parent != null && IsVisible) 
				Parent.InvalidateVisual();
		}
		
		protected virtual void OnInvalidateVisual()
		{
		}

		/**
			Indicates the composition of the visual has changed, but that the visual drawing itself is
			still valid (for example a position change).
		*/
		public void InvalidateVisualComposition()
		{
			OnInvalidateVisualComposition();
			
			var p = Parent;
			if (p != null)
				p.InvalidateVisual();
			else
				InvalidateVisual(); // YUCK: we need to invalidate *something*, otherwise we won't re-render
		}
		
		protected virtual void OnInvalidateVisualComposition()
		{
		}
		
		public int ValidFrameCount
		{
			get { return UpdateManager.FrameIndex - _lastInvalidate; }
		}
	}
}
