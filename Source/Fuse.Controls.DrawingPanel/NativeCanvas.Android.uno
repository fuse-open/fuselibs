using Uno;
using Uno.UX;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Controls.Native;
using Fuse.Controls.Internal;
using Fuse.Input;

namespace Fuse.Controls.Native.Android
{
	[ForeignInclude(Language.Java,
		"android.graphics.Canvas",
		"android.graphics.Bitmap")]
	extern(ANDROID) internal class NativeCanvas : ICanvas
	{
		public Java.Object Bitmap { get { return _bitmap; } }

		Java.Object _bitmapCanvas;
		Java.Object _bitmap;
		int2 _pixelSize;
		float _pixelsPerPoint;

		public NativeCanvas(float2 size, float pixelsPerPoint)
		{
			_pixelSize = (int2)Math.Ceil(size * pixelsPerPoint);
			_pixelsPerPoint = pixelsPerPoint;
			_bitmap = NewBitmap(_pixelSize.X, _pixelSize.Y);
			_bitmapCanvas = NewBitmapCanvas(_bitmap);
		}

		public NativeCanvas(int2 pixelSize) : this((float2)pixelSize, 1.0f) { }

		public void Clear(float4 color)
		{
			_bitmap.Erase(color);
		}

		public void Draw(Line line)
		{
			_bitmapCanvas.Draw(line.Scale(_pixelsPerPoint));
		}

		public void Draw(Internal.Circle circle)
		{
			_bitmapCanvas.Draw(circle.Scale(_pixelsPerPoint));
		}

		public void Draw(IList<Line> lines)
		{
			foreach (var line in lines)
				Draw(line);
		}

		public void Draw(IList<Internal.Circle> circles)
		{
			foreach (var circle in circles)
				Draw(circle);
		}

		public void Draw(Stroke stroke)
		{
			Draw(stroke.Lines);
			Draw(stroke.Circles);
		}

		public void Draw(Bitmap bitmap)
		{
			_bitmapCanvas.DrawBitmap(bitmap.Handle);
		}

		public void PushRotation(float degrees)
		{
			_bitmapCanvas.Save();
			_bitmapCanvas.Rotate(degrees);
		}

		public void PopRotation()
		{
			_bitmapCanvas.Restore();
		}

		public void PushTranslation(float2 translation)
		{
			_bitmapCanvas.Save();
			_bitmapCanvas.Translate(translation.X, translation.Y);
		}

		public void PopTranslation()
		{
			_bitmapCanvas.Restore();
		}

		public void Dispose()
		{
			FreeBitmap(_bitmap);
			_bitmap = null;
			_bitmapCanvas = null;
		}

		public Bitmap AsBitmap()
		{
			return new Bitmap(_bitmap);
		}

		[Foreign(Language.Java)]
		static Java.Object NewBitmap(int width, int height)
		@{
			return Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
		@}

		[Foreign(Language.Java)]
		static Java.Object NewBitmapCanvas(Java.Object bitmap)
		@{
			return new Canvas((Bitmap)bitmap);
		@}

		[Foreign(Language.Java)]
		static void FreeBitmap(Java.Object bitmap)
		@{
			((Bitmap)bitmap).recycle();
		@}
	}

	[ForeignInclude(Language.Java,
		"android.graphics.Canvas",
		"android.graphics.Matrix",
		"android.graphics.Bitmap",
		"android.graphics.Rect",
		"android.graphics.Paint")]
	extern(ANDROID) static class CanvasExtensions
	{
		public static void Clear(this Java.Object canvasHandle, float4 color)
		{
			Clear(canvasHandle, (int)Uno.Color.ToArgb(color));
		}

		[Foreign(Language.Java)]
		static void Clear(Java.Object canvasHandle, int color)
		@{
			int a = color >> 24;
			int r = (color >> 16) & 0xff;
			int g = (color >> 8) & 0xff;
			int b = color & 0xff;
			((Canvas)canvasHandle).drawARGB(a, r, g, b);
		@}

		public static void Draw(this Java.Object canvasHandle, Line line)
		{
			DrawLine(
				canvasHandle,
				line.From.X,
				line.From.Y,
				line.To.X,
				line.To.Y,
				line.Width,
				(int)Uno.Color.ToArgb(line.Color));
		}

		public static void Draw(this Java.Object canvasHandle, Internal.Circle circle)
		{
			DrawCircle(
				canvasHandle,
				circle.Center.X,
				circle.Center.Y,
				circle.Radius,
				(int)Uno.Color.ToArgb(circle.Color));
		}

		[Foreign(Language.Java)]
		static void DrawLine(
			Java.Object canvasHandle,
			float startX,
			float startY,
			float stopX,
			float stopY,
			float width,
			int color)
		@{
			Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
			paint.setStrokeCap(Paint.Cap.ROUND);
			paint.setStrokeWidth(width);
			paint.setColor(color);
			((Canvas)canvasHandle).drawLine(startX, startY, stopX, stopY, paint);
		@}

		[Foreign(Language.Java)]
		static void DrawCircle(
			Java.Object canvasHandle,
			float centerX,
			float centerY,
			float radius,
			int color)
		@{
			Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
			paint.setColor(color);
			((Canvas)canvasHandle).drawCircle(centerX, centerY, radius, paint);
		@}

		[Foreign(Language.Java)]
		public static void DrawBitmap(this Java.Object canvasHandle, Java.Object bitmapHandle)
		@{
			Bitmap bitmap = (Bitmap)bitmapHandle;
			((Canvas)canvasHandle).drawBitmap(bitmap, null, new Rect(0, 0, bitmap.getWidth(), bitmap.getHeight()), null);
		@}

		[Foreign(Language.Java)]
		public static void Translate(this Java.Object canvasHandle, float tx, float ty)
		@{
			((Canvas)canvasHandle).translate(tx, ty);
		@}

		[Foreign(Language.Java)]
		public static void Rotate(this Java.Object canvasHandle, float degrees)
		@{
			((Canvas)canvasHandle).rotate(degrees);
		@}

		[Foreign(Language.Java)]
		public static void Save(this Java.Object canvasHandle)
		@{
			((Canvas)canvasHandle).save();
		@}

		[Foreign(Language.Java)]
		public static void Restore(this Java.Object canvasHandle)
		@{
			((Canvas)canvasHandle).restore();
		@}
	}

	[ForeignInclude(Language.Java,
		"android.graphics.Bitmap")]
	extern(ANDROID) static class BitmapExtensions
	{
		public static void Erase(this Java.Object bitmapHandle, float4 color)
		{
			Erase(bitmapHandle, (int)Uno.Color.ToArgb(color));
		}

		[Foreign(Language.Java)]
		static void Erase(Java.Object bitmapHandle, int color)
		@{
			((Bitmap)bitmapHandle).eraseColor(color);
		@}
	}
}