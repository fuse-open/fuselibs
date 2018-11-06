using Uno;
using Uno.Platform;
using Uno.UX;
using Fuse;
using Fuse.Input;
using Fuse.Animations;
using Fuse.Drawing;
using Fuse.Elements;

namespace Fuse.Controls
{
	/** Controls display a native control or graphics-based control based on context.

		@topic Controls

		In Fuse, UI Controls refers to the common components for interaction and data entry typically found in most operating systems and UI kits.

		Fuse gives you access to two different technologies for displaying UI Controls:

		* Fully portable custom controls drawn by OpenGL (default, see @GraphicsView)
		* The real native controls provided from the OS itself (see @NativeViewHost)

		In a native context (inside of a @NativeViewHost ), controls will display a native control, if supported for
		the given control an platform. In other context, the graphics-based appearance will be used.

		## Available UI controls

		[subclass Fuse.Controls.Control]

		## Adding more UI controls

		You can create your own UI controls in two ways:

		* Extend an existing control in UX markup using @ux:Class
		* Creating [custom UX wrappers for native controls](https://fuseopen.com/docs/native-interop/native-ux-components)

	*/	
	public abstract partial class Control: Element
	{
		protected override void OnDraw(DrawContext dc)
		{
			DrawBackground(dc, 1.0f);
			DrawVisual(dc);
		}

		protected virtual void DrawVisual(DrawContext dc) { }

		protected override void OnHitTestLocalVisual(HitTestContext htc)
		{
			if (Background != null && IsPointInside(htc.LocalPoint))
				htc.Hit(this);

			base.OnHitTestLocalVisual(htc);
		}

		protected override VisualBounds HitTestLocalVisualBounds
		{
			get
			{
				var nb = base.HitTestLocalVisualBounds;
				if (Background != null)
					nb = nb.AddRect( float2(0), ActualSize );
				return nb;
			}
		}
		
		protected override VisualBounds CalcRenderBounds()
		{
			var b = base.CalcRenderBounds();
			if (Background != null)
				b = b.AddRect( float2(0), ActualSize );
			return b;
		}
	}
}