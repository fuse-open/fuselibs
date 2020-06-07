using Uno;
using Uno.Collections;
using Uno.UX;
using Fuse.Layouts;
using Fuse.Elements;

using Fuse.Drawing;

namespace Fuse.Controls
{
	/**
		Combines several child vector elements into a single drawing.

		This may be used to improve performance when drawing several `ISurfaceDrawable` elements into the same control. The actual performance improvement depends greatly on what is being drawn, and how many elements are involved.

		All ancestors must be `ISurfaceDrawable` to be used in a `VectorLayer`. A warning will be issused, but the actual behavior is undefined.

		@advanced
	*/
	public class VectorLayer : LayoutControl, ISurfaceDrawable, ISurfaceProvider
	{
		protected sealed override void DrawWithChildren(DrawContext dc)
		{
			LayoutSurface.Draw(dc, this, this );
		}

		void ISurfaceDrawable.Draw(Surface surface) { ISurfaceDrawableDraw(surface); }
		bool ISurfaceDrawable.IsPrimary { get { return true; } }
		float2 ISurfaceDrawable.ElementSize { get { return ActualSize; } }

		protected override void OnRooted()
		{
			base.OnRooted();
			SurfaceRooted(true);
		}

		protected override void OnUnrooted()
		{
			SurfaceUnrooted();
			base.OnUnrooted();
		}
	}
}
