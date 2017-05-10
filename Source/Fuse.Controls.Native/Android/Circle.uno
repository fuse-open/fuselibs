using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Drawing;

namespace Fuse.Controls.Native.Android
{

	[ForeignInclude(Language.Java, "android.graphics.RectF")]
	extern(Android) internal class Circle : Shape, ICircleView
	{
	
		float _startAngle = 0.0f;
		float ICircleView.StartAngleDegrees
		{
			set
			{
				_startAngle = value;
				OnShapeChanged();
			}
		}

		float _endAngle = 0.0f;
		float ICircleView.EndAngleDegrees
		{
			set
			{
				_endAngle = value;
				OnShapeChanged();
			}
		}

		bool _useAngle = false;
		bool ICircleView.UseAngle
		{
			set
			{
				_useAngle = value;
				OnShapeChanged();
			}
		}

		float ICircleView.EffectiveEndAngleDegrees { set { } }

		protected sealed override void UpdateShapeDrawable(Java.Object handle, float pixelsPerPoint)
		{
			UpdateShapeDrawable(handle, _useAngle, Size.X, Size.Y, _startAngle, _endAngle);
		}

		internal protected sealed override void OnSizeChanged()
		{
			OnShapeChanged();
		}

		[Foreign(Language.Java)]
		void UpdateShapeDrawable(Java.Object handle, bool useAngle, float width, float height, float startAngle, float endAngle)
		@{
			android.graphics.drawable.ShapeDrawable sd = (android.graphics.drawable.ShapeDrawable)handle;
			float start = useAngle ? startAngle : 0.0f;
			float end = useAngle ? endAngle : 360.0f;
			android.graphics.Path path = new android.graphics.Path();
			path.addArc(new RectF(0.0f, 0.0f, width, height), start, end - start);
			android.graphics.drawable.shapes.PathShape ps = new android.graphics.drawable.shapes.PathShape(path, width, height);
			sd.setShape(ps);
		@}
	}

}
