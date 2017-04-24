using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Drawing;

namespace Fuse.Controls.Native.Android
{
	extern(Android) internal class Ellipse : Shape
	{
		protected sealed override void UpdateShapeDrawable(Java.Object handle, float pixelsPerPoint)
		{
			UpdateShapeDrawable(handle);
		}

		[Foreign(Language.Java)]
		void UpdateShapeDrawable(Java.Object handle)
		@{
			android.graphics.drawable.ShapeDrawable sd = (android.graphics.drawable.ShapeDrawable)handle;
			android.graphics.drawable.shapes.OvalShape oval = new android.graphics.drawable.shapes.OvalShape();
			sd.setShape(oval);
		@}

	}

}