using Uno;
using Uno.UX;

namespace Fuse.Elements
{
	public abstract partial class Element
	{
		protected override void OnInvalidateVisual()
		{
			base.OnInvalidateVisual();
			if (Cache != null)
				Cache.Invalidate();

			if (ElementBatchEntry != null)
				ElementBatchEntry.InvalidateVisual();
		}

		protected override void OnInvalidateVisualComposition()
		{
			base.OnInvalidateVisualComposition();
			if (ElementBatchEntry != null)
				ElementBatchEntry.InvalidateVisualComposition();
		}

		protected override void OnInvalidateLayout()
		{
			base.OnInvalidateLayout();
			GMSReset();
		}

		protected override LayoutDependent IsMarginBoxDependent( Visual child )
		{
			return _boxSizing.IsContentRelativeSize(this);
		}

		protected override bool OnInvalidateRenderBounds()
		{
			//stop propagation to parent if already dirty
			if (_renderBoundsWithEffects == null && _renderBoundsWithoutEffects == null)
				return true;
				
			_renderBoundsWithoutEffects = null;
			OnInvalidateRenderBoundsWithEffects();

			if (ElementBatchEntry != null)
				ElementBatchEntry.InvalidateRenderBounds();

			return false;
		}

		void OnInvalidateRenderBoundsWithEffects()
		{
			if (ElementBatchEntry != null)
				ElementBatchEntry.InvalidateRenderBounds();

			_renderBoundsWithEffects = null;
		}

		
		public void InvalidateRenderBoundsWithEffects()
		{
			OnInvalidateRenderBoundsWithEffects();

			if (Parent != null)
				Parent.InvalidateRenderBounds();
		}
	}
}
