using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using OpenGL;

using Fuse.Common;
using Fuse.Elements;
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
		"com.fuse.drawing.surface.LinearGradientStore",
		"com.fuse.drawing.surface.GraphicsSurfaceContext"
	)]
	[ForeignInclude(Language.Java,
		"java.nio.ByteBuffer",
		"java.nio.IntBuffer",
		"java.nio.ByteOrder",
		"java.nio.FloatBuffer"
	)]
	extern(Android)
	class GraphicsSurface : AndroidSurface
	{
		framebuffer _buffer;
		float2 _size;
		DrawContext _drawContext;

		public override void Begin(DrawContext dc, framebuffer fb, float pixelsPerPoint)
		{
			base.Begin(dc, fb, pixelsPerPoint);

			var impl = SurfaceContext;
			_drawContext = dc;
			_buffer = fb;
			_size = (float2)fb.Size / pixelsPerPoint;

			// return early if framebuffer has no size to prevent runtime crashes
			if (fb.Size.X == 0 || fb.Size.Y == 0)
			{
				return;
			}
			LoadBitmap(impl, fb.Size.X, fb.Size.Y);
			BeginImpl(impl, fb.Size.X, fb.Size.Y, (int)fb.ColorBuffer.GLTextureHandle);
		}

		/**
			Load a bitmap of given dimensions into the context and use it for the canvas
		*/
		[Foreign(Language.Java)]
		public static extern(Android) void LoadBitmap(Java.Object context, int width, int height)
		@{
			GraphicsSurfaceContext impl = (GraphicsSurfaceContext) context;
			Bitmap b = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);

			Canvas canvas = impl.canvas;
			canvas.setBitmap(b);
			impl.bitmap = b;

			canvas.setMatrix(null);

			// invert our bitmap since the Android canvas is inversed when drawing
			canvas.translate(0.0f, (float)height);
			canvas.scale(1, -1);
		@}

		[Foreign(Language.Java)]
		static void BeginImpl(Java.Object _context, int width, int height, int glTextureId)
		@{
			GraphicsSurfaceContext context = (GraphicsSurfaceContext) _context;
			context.width = width;
			context.height = height;
			context.glTextureId = glTextureId;
		@}

		/**
			Ends drawing. All drawing called after `Begin` and to now must be completed by now. This copies the resulting image to the desired output setup in `Begin`.
		*/
		public override void End()
		{
			var impl = SurfaceContext;

			if (impl == null) return;
			EndImpl(impl);
		}

		[Foreign(Language.Java)]
		static void EndImpl(Java.Object context)
		@{
			GraphicsSurfaceContext realContext = (GraphicsSurfaceContext) context;

			GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, realContext.glTextureId);

			// heat up the caches. not needed but good to have
			realContext.bitmap.prepareToDraw();

			GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, realContext.bitmap, 0);
			realContext.bitmap.recycle();
		@}

		protected sealed override void VerifyBegun()
		{
			if (_buffer == null)
				throw new Exception( "Canvas.Begin was not called" );
		}
	}
}
