using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;
using Uno.Collections;
using Uno.Collections.EnumerableExtensions;
using Fuse.Drawing;

namespace Fuse.Controls.Native.Android
{

	extern(Android) internal abstract class Shape : View, IShapeView
	{
		Java.Object _drawable;

		protected Shape() : base(Create())
		{

		}

		Stroke[] _strokes;
		Brush[] _fills;
		float _pixelsPerPoint;

		void IShapeView.Update(Brush[] fills, Stroke[] strokes, float pixelsPerPoint)
		{
			_fills = fills;
			_strokes = strokes;
			_pixelsPerPoint = pixelsPerPoint;
			OnShapeChanged();
		}

		protected abstract void UpdateShapeDrawable(Java.Object handle, float pixelsPerPoint);

		protected void OnShapeChanged()
		{
			var layerCount =
				(_fills != null ? _fills.Length : 0) +
				(_strokes != null ? _strokes.Length : 0);

			var layerDrawable = MakeLayerDrawable(Handle, layerCount);

			for (var i = 0; i < layerCount; i++)
			{
				UpdateShapeDrawable(GetLayer(layerDrawable, i), _pixelsPerPoint);
			}

			int layer = 0;
			if (_fills != null)
			{
				for (var i = _fills.Length; i --> 0;)
					SetBrush(GetLayer(layerDrawable, layer++), _fills[i]);
			}

			if (_strokes != null)
			{
				for (var i = _strokes.Length; i --> 0;)
					SetStroke(GetLayer(layerDrawable, layer++), _strokes[i]);
			}
		}

		void SetStroke(Java.Object shapeDrawable, Stroke stroke)
		{
			if (stroke.Brush != null)
				SetBrush(shapeDrawable, stroke.Brush);

			SetShapeDrawableStrokeWidth(shapeDrawable, stroke.Width * _pixelsPerPoint);
		}

		void SetBrush(Java.Object shapeDrawable, Brush brush)
		{
			if (brush is LinearGradient)
			{
				SetLinearGradient(shapeDrawable, (LinearGradient)brush);
			}
			else
			{
				var c = float4(0);
				var sc = brush as Fuse.Drawing.SolidColor;
				if (sc != null)
					c = sc.Color;
				var ssc = brush as Fuse.Drawing.StaticSolidColor;
				if (ssc != null)
					c = ssc.Color;

				if (sc == null && ssc == null)
					Fuse.Diagnostics.Unsupported( "", brush );

				var db = brush as DynamicBrush;
				var opacity = db != null ? db.Opacity : 1.0f;

				SetShapeDrawableColor(
					shapeDrawable,
					Math.Clamp((int)(c.X * 255.0f), 0, 255),
					Math.Clamp((int)(c.Y * 255.0f), 0, 255),
					Math.Clamp((int)(c.Z * 255.0f), 0, 255),
					Math.Clamp((int)(c.W * 255.0f), 0, 255),
					Math.Clamp((int)(opacity * 255.0f), 0, 255));
			}

		}

		static int SelectOffset(GradientStop a, GradientStop b)
		{
			return (int)Math.Sign(a.Offset - b.Offset);
		}

		void SetLinearGradient(Java.Object shapeDrawable, LinearGradient linearGradient)
		{
			var stops = OrderBy(linearGradient.Stops, SelectOffset).ToArray();
			var colors = new int[stops.Length];
			var positions = new float[stops.Length];

			for (var i = 0; i < stops.Length; i++)
			{
				var gradientStop = stops[i];
				colors[i] = (int)Color.ToArgb(gradientStop.Color);
				positions[i] = gradientStop.Offset;
			}

			var start = linearGradient.StartPoint;
			var end = linearGradient.EndPoint;

			SetShapeDrawableLinearGradient(
				shapeDrawable,
				start.X,
				start.Y,
				end.X,
				end.Y,
				colors,
				positions);
		}

		[Foreign(Language.Java)]
		static void SetShapeDrawableLinearGradient(
			Java.Object shapeDrawable,
			float startX,
			float startY,
			float endX,
			float endY,
			int[] colors,
			float[] positions)
		@{
			android.graphics.drawable.ShapeDrawable sd = (android.graphics.drawable.ShapeDrawable)shapeDrawable;
			sd.setShaderFactory(new android.graphics.drawable.ShapeDrawable.ShaderFactory() {

				public android.graphics.Shader resize(int width, int height) {
						return new android.graphics.LinearGradient(
							startX,
							startY,
							width * endX,
							height * endY,
							colors.copyArray(),
							positions.copyArray(),
							android.graphics.Shader.TileMode.CLAMP);
					}

				});
		@}


		[Foreign(Language.Java)]
		static void SetShapeDrawableColor(Java.Object shapeDrawable, int r, int g, int b, int a, int opacity)
		@{
			android.graphics.drawable.ShapeDrawable sd = (android.graphics.drawable.ShapeDrawable)shapeDrawable;
			sd.getPaint().setARGB(a, r, g, b);
			sd.setAlpha(opacity);
		@}

		[Foreign(Language.Java)]
		static void SetShapeDrawableStrokeWidth(Java.Object shapeDrawable, float width)
		@{
			android.graphics.drawable.ShapeDrawable sd = (android.graphics.drawable.ShapeDrawable)shapeDrawable;
			sd.getPaint().setStyle(android.graphics.Paint.Style.STROKE);
			sd.getPaint().setStrokeWidth(width);
		@}

		[Foreign(Language.Java)]
		static Java.Object Create()
		@{
			return new android.view.View(com.fuse.Activity.getRootActivity());
		@}

		[Foreign(Language.Java)]
		static Java.Object CreateShapeDrawable()
		@{
			return new android.graphics.drawable.ShapeDrawable();
		@}

		[Foreign(Language.Java)]
		static Java.Object GetLayer(Java.Object handle, int layer)
		@{
			android.graphics.drawable.LayerDrawable layerDrawable = (android.graphics.drawable.LayerDrawable)handle;
			return layerDrawable.getDrawable(layer);
		@}

		[Foreign(Language.Java)]
		static Java.Object MakeLayerDrawable(Java.Object handle, int layerCount)
		@{
			android.view.View view = (android.view.View)handle;
			android.graphics.drawable.Drawable[] drawables = new android.graphics.drawable.Drawable[layerCount];

			for (int i = 0; i < layerCount; i++)
			{
				drawables[i] = new android.graphics.drawable.ShapeDrawable();
			}

			android.graphics.drawable.LayerDrawable layerDrawable = new android.graphics.drawable.LayerDrawable(drawables);

			if (android.os.Build.VERSION.SDK_INT >= 16)
			{
				view.setBackground(layerDrawable);
			}
			else
			{
				view.setBackgroundDrawable(layerDrawable);
			}

			return layerDrawable;
		@}

	}

}
