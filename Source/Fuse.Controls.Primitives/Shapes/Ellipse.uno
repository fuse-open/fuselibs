using Uno;
using Uno.UX;

using Fuse.Drawing;
using Fuse.Controls.Native;

namespace Fuse.Controls
{
	[Obsolete]
	/** Displays an ellipse

		Ellipse is a @Shape that can have @Fills and @Strokes.
		By default Ellipse does not have a size, fills or strokes. You must add some for it
		to become visible.

		## Example:

			<Ellipse Width="300" Height="100">
				<LinearGradient>
					<GradientStop Offset="0" Color="#0cc" />
					<GradientStop Offset="1" Color="#cc0" />
				</LinearGradient>
				<Stroke Width="1">
					<SolidColor Color="#000" />
				</Stroke>
			</Ellipse>

	*/
	public partial class Ellipse : EllipticalShape
	{
		protected override IView CreateNativeView()
		{
			if defined(Android)
			{
				return new Fuse.Controls.Native.Android.Ellipse();
			}
			else if defined (iOS)
			{
				return new Fuse.Controls.Native.iOS.Ellipse();
			}
			else return base.CreateNativeView();
		}
		
		protected override bool NeedSurface { get { return true; } }
		
		protected override SurfacePath CreateSurfacePath(Surface surface)
		{
			return CreateEllipticalPath( surface, ActualSize/2, ActualSize/2 );
		}
	}
}
