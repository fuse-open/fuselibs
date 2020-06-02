using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using OpenGL;

using Fuse.Common;
using Fuse.Drawing.Primitives;

namespace Fuse.Drawing
{
	[Require("Xcode.Framework","CoreGraphics")]
	[Require("Source.Include", "CoreGraphics/CoreGraphicsLib.h")]
	[Require("Xcode.Framework","GLKit")]
	[extern(OSX) Require("Source.Include","XliPlatform/GL.h")]
	[extern(iOS) Require("Source.Include","OpenGLES/ES2/gl.h")]
	extern(iOS||OSX)
	class GraphicsSurface : CoreGraphicsSurface
	{
		DrawContext _drawContext;
		framebuffer _buffer;
		float2 _size;

		public override void Begin( DrawContext dc, framebuffer fb, float pixelsPerPoint )
		{
			VerifyCreated();
			_drawContext = dc;
			_buffer = fb;
			_pixelsPerPoint = pixelsPerPoint;
			_size = (float2)fb.Size / pixelsPerPoint;
			if (!BeginImpl(_context, fb.Size.X, fb.Size.Y, (int)fb.ColorBuffer.GLTextureHandle))
				throw new Exception("Failed to create Surface object");
		}

		[Foreign(Language.CPlusPlus)]
		static bool BeginImpl(IntPtr cp, int width, int height, int glTexture)
		@{
			auto ctx = (CGLib::Context*)cp;
			auto bytesPerRow = width * 4;
			auto byteCount = bytesPerRow * height;

			ctx->GLTexture = glTexture;

			//can we reuse the last context?
			if (ctx->Context && ctx->Width == width && ctx->Height == height)
			{
				memset(ctx->BitmapData, 0, byteCount);
				if (!ctx->ResetState())
				{
					@{Fuse.Diagnostics.InternalError(string, object, string, int, string):Call(uString::Utf8("Failed to reset  state"), NULL, uString::Utf8(__FILE__), __LINE__, uString::Utf8(""))};
				}
				ctx->SaveState();
				return true;
			}
			else if (ctx->Context)
			{
				ctx->ReleaseContext();
			}

			ctx->Width = width;
			ctx->Height = height;

			ctx->BitmapData = malloc(byteCount);
			if (!ctx->BitmapData)
			{
				@{Fuse.Diagnostics.InternalError(string, object, string, int, string):Call(uString::Utf8("Failed to allocate bitmap data"), NULL, uString::Utf8(__FILE__), __LINE__, uString::Utf8(""))};
				return false;
			}
			memset(ctx->BitmapData, 0, byteCount);

			ctx->Context = CGBitmapContextCreate(ctx->BitmapData, ctx->Width, ctx->Height, 8,
				bytesPerRow, ctx->ColorSpace, kCGImageAlphaPremultipliedLast);
			if (!ctx->Context)
			{
				@{Fuse.Diagnostics.InternalError(string, object, string, int, string):Call(uString::Utf8("Failed to create CGBitmapContext"), NULL, uString::Utf8(__FILE__), __LINE__, uString::Utf8(""))};
				return false;
			}
			ctx->SaveState();
			return true;
		@}

		public override void End()
		{
			VerifyBegun();
			EndImpl(_context);
			_buffer = null;
		}

		[Foreign(Language.CPlusPlus)]
		static void EndImpl(IntPtr cp)
		@{
			auto ctx = (CGLib::Context*)cp;
			glBindTexture(GL_TEXTURE_2D, ctx->GLTexture);
			glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
			glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, ctx->Width, ctx->Height, 0, GL_RGBA,
				GL_UNSIGNED_BYTE, ctx->BitmapData);

			//There's no indication the context reuse is actually faster, and since it keeps resources
			//around it's been disabled for now
			ctx->ReleaseContext();
		@}

		protected override void VerifyBegun()
		{
			if (_buffer == null)
				throw new Exception( "Surface.Begin was not called" );
		}
	}
}
