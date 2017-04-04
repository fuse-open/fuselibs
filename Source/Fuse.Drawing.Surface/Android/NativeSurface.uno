using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using OpenGL;

using Fuse.Elements;
using Fuse.Drawing;
using Fuse.Drawing.Primitives;

namespace Fuse.Drawing
{
	[ForeignInclude(Language.Java,
		"android.graphics.Canvas",
		"android.graphics.Bitmap",
		"android.graphics.Shader",
		"android.graphics.BitmapShader",
		"android.graphics.drawable.BitmapDrawable",
		"android.graphics.Rect",
		"android.graphics.RectF",
		"android.graphics.Path",
		"android.opengl.GLUtils",
		"android.opengl.GLES20",
		"android.graphics.Paint",
		"android.graphics.LinearGradient",
		"android.graphics.Shader.TileMode",
		"android.graphics.Color",
		"android.graphics.PorterDuffXfermode",
		"android.graphics.Matrix",
		"android.graphics.PorterDuff.Mode",
		"com.fusetools.drawing.surface.LinearGradientStore",
		"com.fusetools.drawing.surface.ISurfaceContext",
	)]
	[ForeignInclude(Language.Java,
		"java.nio.ByteBuffer",
		"java.nio.IntBuffer",
		"java.nio.ByteOrder",
		"java.nio.FloatBuffer"
	)]
	extern(Android)
	internal class NativeSurface : AndroidSurface
	{
		protected sealed override Java.Object SurfaceContext
		{
			get { return _context; }
		}

		Java.Object _context;
		Java.Object _canvas;

		public NativeSurface()
		{
			_context = NewContext(GetCanvas);
		}

		Java.Object GetCanvas()
		{
			return _canvas;
		}

		[Foreign(Language.Java)]
		static Java.Object NewContext(Func<Java.Object> getCanvasFunc)
		@{
			return new ISurfaceContext() {
				public Canvas getCanvas() {
					return (Canvas)getCanvasFunc.run();
				}
			};
		@}

		public void Begin(Java.Object canvas, float pixelsPerPoint)
		{
			_canvas = canvas;
			_pixelsPerPoint = pixelsPerPoint;
		}

		public override void Begin(DrawContext dc, framebuffer fb, float pixelsPerPoint)
		{
			throw new NotSupportedException();
		}

		public override void End()
		{
			_canvas = null;
		}

		protected sealed override Java.Object PrepareImageFillImpl( ImageFill img )
		{
			//TODO: must be completed, or least a warning and the empty item cached.
			return DummyBitmap();
		}
		
		[Foreign(Language.Java)]
		static Java.Object DummyBitmap()
		@{
			return Bitmap.createBitmap(10,10,Bitmap.Config.ARGB_8888);
		@}

		protected sealed override void VerifyBegun()
		{
			if (_canvas == null)
				throw new Exception( "Canvas.Begin was not called" );
		}

		public override void Dispose()
		{
			base.Dispose();
			_context = null;
			_canvas = null;
		}
	}
}