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
			_canvas = NewCanvas();
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

		[Foreign(Language.Java)]
		static Java.Object NewCanvas()
		@{
			return new Canvas();
		@}

		public void SetCanvas(Java.Object canvas)
		{
			_canvas = canvas;
		}

		public override void Begin(DrawContext dc, framebuffer fb, float pixelsPerPoint)
		{
			throw new NotSupportedException();
		}

		public override void End()
		{
			throw new NotSupportedException();
		}

		protected sealed override Java.Object PrepareImageFillImpl( ImageFill img )
		{
			throw new NotImplementedException();
		}

		protected sealed override void VerifyBegun()
		{
		}

		public override void Dispose()
		{
			base.Dispose();
			_context = null;
			_canvas = null;
		}
	}
}