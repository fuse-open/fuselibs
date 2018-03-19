using Uno;
using Uno.UX;

using Fuse.Drawing;
using Fuse.Controls.Native;

namespace Fuse.Controls
{
	/** 
		Displays an arc.

		Arc is a @Shape that can have @Strokes. An Arc is equivalent to a stroke on the circumference of an @Ellipse (an Arc has no lines to/from the center as a stroke on the @Ellipse would have).
		
		It is undefined what shape is filled if a `Fill` is used on an Arc. Use only a stroke.
	*/
	public partial class Arc : EllipticalShape
	{
		//https://github.com/fusetools/fuselibs-private/issues/3877
		/*protected override IView CreateNativeView()
		{
			//https://github.com/fusetools/fuselibs-private/issues/3877
			if defined(Android)
			{
				return new Fuse.Controls.Native.Android.Ellipse();
			}
			else if defined (iOS)
			{
				return new Fuse.Controls.Native.iOS.Ellipse(this);
			}
			else return base.CreateNativeView();
		}*/
		
		protected override SurfacePath CreateSurfacePath(Surface surface)
		{
			return CreateEllipticalPath( surface, ActualSize/2, ActualSize/2, true );
		}
	}
}
