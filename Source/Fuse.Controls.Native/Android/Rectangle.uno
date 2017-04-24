using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Drawing;

namespace Fuse.Controls.Native.Android
{

	extern(Android) internal class Rectangle : Shape, IRectangleView
	{
		float4 _cornerRadius = float4(0.0f);
		float4 IRectangleView.CornerRadius
		{
			set
			{
				_cornerRadius = value;
				OnShapeChanged();
			}
		}

		protected sealed override void UpdateShapeDrawable(Java.Object handle, float pixelsPerPoint)
		{
			var r = _cornerRadius * pixelsPerPoint;
			UpdateShapeDrawable(handle, r.X, r.Y, r.Z, r.W);
		}

		[Foreign(Language.Java)]
		void UpdateShapeDrawable(Java.Object handle, float x, float y, float z, float w)
		@{
			android.graphics.drawable.ShapeDrawable sd = (android.graphics.drawable.ShapeDrawable)handle;
			float[] cornerRadius = { x, x, y, y, z, z, w, w };
			android.graphics.drawable.shapes.RoundRectShape rrs = new android.graphics.drawable.shapes.RoundRectShape(cornerRadius, null, null);
			sd.setShape(rrs);
		@}

	}

}