using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using OpenGL;

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

		/*
			This approach is really bad now. When Erik refactors ImageSource we shouldn't
			need to do the round-trip to GL.
			We might end up not supporting ImageFill until this is fixed, but this is useful
			here now to complete/test the sizing/tiling support.
		*/
		protected override void PrepareImageFill( ImageFill img )
		{
			var src = img.Source;
			var tex = src.GetTexture();
			if (tex == null) //probably still loading
				return;

			IntPtr imageRef;

			if defined(OSX)
			{
				imageRef = LoadImage(_context, (int)tex.GLTextureHandle, src.PixelSize.X, src.PixelSize.Y );
			}
			else
			{
				var fb = FramebufferPool.Lock( src.PixelSize, Uno.Graphics.Format.RGBA8888, false );

				//TODO: this is not entirely correct since _drawContext could be null now -- but it isn't
				//in any of our use cases, but the contract certainly allows for it
				_drawContext.PushRenderTarget(fb);
				Blitter.Singleton.Blit(tex, new Rect(float2(-1), float2(2)), float4x4.Identity, 1.0f, true);
				imageRef = LoadImagePoor(_context, src.PixelSize.X, src.PixelSize.Y );
				FramebufferPool.Release(fb);
				_drawContext.PopRenderTarget();
			}
			_imageBrushes[img] = imageRef;
		}

		[Foreign(Language.CPlusPlus)]
		static IntPtr LoadImagePoor(IntPtr cp, int width, int height)
		@{
			auto ctx = (CGLib::Context*)cp;
			int size = width * height * 4;
			auto pixelData = new UInt8[size];
			glPixelStorei(GL_PACK_ALIGNMENT, 1);
			glReadPixels(0,0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, pixelData);

			CFDataRef data = CFDataCreate(NULL, pixelData, size);
			CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
			CGImageRef imageRef = CGImageCreate(width, height, 8, 32, width * 4, ctx->ColorSpace,
				kCGBitmapByteOrderDefault, provider, NULL, true, kCGRenderingIntentDefault);

			CGDataProviderRelease(provider);
			CFRelease(data);
			delete[] pixelData;
			return imageRef;
		@}

		[Foreign(Language.CPlusPlus)]
		extern(OSX) static IntPtr LoadImage(IntPtr cp, int glTexture, int width, int height)
		@{
			auto ctx = (CGLib::Context*)cp;
			int rowSize = width * 4;
			int size = rowSize * height;
			auto pixelData = new UInt8[size];
			glBindTexture(GL_TEXTURE_2D, glTexture);
			glPixelStorei(GL_PACK_ALIGNMENT, 1);
			glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixelData);

			//flip the image
			auto tempRow = new UInt8[rowSize];
			for (int y=0; y < height/2; ++y)
			{
				memcpy( tempRow, pixelData + y * rowSize, rowSize );
				memcpy( pixelData + y * rowSize, pixelData + (height-y-1) * rowSize, rowSize );
				memcpy( pixelData + (height-y-1) * rowSize, tempRow, rowSize );
			}

			CFDataRef data = CFDataCreate(NULL, pixelData, size);
			CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
			CGImageRef imageRef = CGImageCreate(width, height, 8, 32, width * 4, ctx->ColorSpace,
				kCGBitmapByteOrderDefault, provider, NULL, true, kCGRenderingIntentDefault);

			CGDataProviderRelease(provider);
			CFRelease(data);
			delete[] pixelData;
			delete[] tempRow;
			return imageRef;
		@}
	}
}
