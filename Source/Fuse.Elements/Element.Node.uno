using Uno;
using Uno.Collections;
using Uno.UX;

namespace Fuse.Elements
{
	public abstract partial class Element: Visual, IActualPlacement, Fuse.Animations.IResize
	{
		void Fuse.Animations.IResize.SetSize(float2 size)
		{
			//TODO: Ugh, not even sure how this works correctly
			_actualSize = size;
			InternArrangePaddingBox(LayoutParams.CreateTemporary(size));

			//TODO: this duplicates what is done in PerformPlacement
			InvalidateVisual();
			InvalidateRenderBounds();
			InvalidateLocalTransform();
		}


		protected virtual bool IsSelectionParentOf(Element elm)
		{
			return false;
		}

		protected override void OnRooted()
		{
			base.OnRooted();

			NotifyTreeRendererRooted();

			InvalidateVisualComposition();

			//clears the placement/layout status
			_placedBefore = null;

			if defined(Designer)
			{
				NotifyRooted();
			}
		}

		protected override void OnUnrooted()
		{
			InvalidateVisualComposition();

			base.OnUnrooted();

			NotifyTreeRendererUnrooted();

			CleanupBatching();

			if defined(Designer)
			{
				NotifyUnrooted();
			}
		}

		public override bool IsLocalVisible { get { return Visibility == Visibility.Visible; } }
	}
}
