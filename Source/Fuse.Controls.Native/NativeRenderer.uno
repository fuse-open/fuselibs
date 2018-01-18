using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.Graphics;
using Fuse.Common;
using OpenGL;

namespace Fuse.Controls.Native
{
	extern(Android || iOS)
	public interface IViewHandleRenderer : IDisposable
	{
		void Draw(ViewHandle viewHandle, float4x4 localToClipTransform, float2 position, float2 size, float density);
		void Invalidate();
	}

	extern(Android || iOS)
	public class NativeViewRenderer : IDisposable, IViewHandleRenderer
	{
		object _pixelBuffer;

		GLTextureHandle _textureHandle;
		bool _valid = false;

		int2 _prevSize = int2(-1);
		public void Draw(
			ViewHandle viewHandle,
			float4x4 localToClipTransform,
			float2 position,
			float2 size,
			float density)
		{
			var pixelSize = (int2)(size * density);
			var reuse = true;

			if (_prevSize != pixelSize)
			{
				ReleaseResources();
				_textureHandle = GL.CreateTexture();
				_pixelBuffer = AllocPixelBuffer(pixelSize.X, pixelSize.Y);
				_prevSize = pixelSize;
				reuse = false;
				_valid = false;
			}

			if (!_valid)
			{
				GL.BindTexture(GLTextureTarget.Texture2D, _textureHandle);
				if defined(Android)
				{
					Upload(
						viewHandle.NativeHandle,
						(Java.Object)_pixelBuffer,
						reuse,
						pixelSize.X,
						pixelSize.Y);
				}
				else if defined(iOS)
				{
					Upload(
						viewHandle.NativeHandle,
						(int)_textureHandle,
						(IntPtr)_pixelBuffer,
						pixelSize.X,
						pixelSize.Y,
						density,
						reuse);
				}
				GL.BindTexture(GLTextureTarget.Texture2D, GLTextureHandle.Zero);
				_valid = true;
			}
			Blitter.Singleton.Blit(
				new texture2D(_textureHandle, pixelSize, 1, Format.RGBA8888),
				new Rect(position, size),
				localToClipTransform,
				1.0f,
				defined(iOS));
		}

		public void Invalidate()
		{
			_valid = false;
		}

		public void Dispose()
		{
			ReleaseResources();
		}

		void ReleaseResources()
		{
			if (_textureHandle != GLTextureHandle.Zero)
			{
				GL.DeleteTexture(_textureHandle);
				_textureHandle = GLTextureHandle.Zero;
			}
			if (_pixelBuffer != null)
			{
				if defined(Android)
					FreePixelBuffer((Java.Object)_pixelBuffer);
				else if defined(iOS)
					FreePixelBuffer((IntPtr)_pixelBuffer);
				_pixelBuffer = null;
			}
		}

		[Foreign(Language.ObjC)]
		[Require("Xcode.Framework", "GLKit")]
		[Require("Source.Include", "UIKit/UIKit.h")]
		[Require("Source.Include", "CoreGraphics/CoreGraphics.h")]
		[Require("Source.Include", "GLKit/GLKit.h")]
		[Require("Source.Include", "OpenGLES/EAGL.h")]
		[Require("Source.Include", "QuartzCore/QuartzCore.h")]
		extern(iOS)
		static void Upload(
			ObjC.Object viewHandle,
			int textureName,
			IntPtr pixelBufferHandle,
			int width,
			int height,
			float density,
			bool reuse)
		@{
			::UIView* view = (::UIView*)viewHandle;
			GLubyte* pixelBuffer = (GLubyte*)pixelBufferHandle;

			CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
			CGContextRef context = CGBitmapContextCreate(
				pixelBuffer,
				width,
				height,
				8,
				4 * width,
				colorSpace,
				kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);

			CGContextClearRect(context, { { 0.0f, 0.0f, }, { (CGFloat)width, (CGFloat)height } });
			CGContextScaleCTM(context, (CGFloat)density, (CGFloat)density);

			if ([viewHandle isKindOfClass: [UIScrollView class]])
			{
				auto scrollview = (UIScrollView*)viewHandle;
				auto offset = [scrollview contentOffset];
				CGContextTranslateCTM(context, -offset.x, -offset.y);
			}

			CGColorSpaceRelease(colorSpace);

			[[view layer] renderInContext:context];

			glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
			if (reuse)
			{
				glTexSubImage2D(
					GL_TEXTURE_2D,
					0,
					0,
					0,
					width,
					height,
					GL_RGBA,
					GL_UNSIGNED_BYTE,
					pixelBuffer);

			}
			else
			{
				glTexImage2D(
					GL_TEXTURE_2D,
					0,
					GL_RGBA,
					width,
					height,
					0,
					GL_RGBA,
					GL_UNSIGNED_BYTE,
					pixelBuffer);
			}
			CGContextRelease(context);
		@}

		[Foreign(Language.Java)]
		extern(Android)
		static void Upload(Java.Object viewHandle, Java.Object pixelBuffer, bool reuse, int w, int h)
		@{
			android.view.View view = (android.view.View)viewHandle;

			view.measure(
				android.view.View.MeasureSpec.makeMeasureSpec(w, android.view.View.MeasureSpec.EXACTLY),
				android.view.View.MeasureSpec.makeMeasureSpec(h, android.view.View.MeasureSpec.EXACTLY));

			view.layout(0, 0, w, h);
			android.graphics.Bitmap bitmap = (android.graphics.Bitmap)pixelBuffer;
			android.graphics.Canvas canvas = new android.graphics.Canvas(bitmap);

			int scrollX = view.getScrollX();
			int scrollY = view.getScrollY();
			canvas.translate(-(float)scrollX, -(float)scrollY);

			bitmap.eraseColor((int)0x00000000);

			view.draw(canvas);

			if (reuse)
			{
				android.opengl.GLUtils.texSubImage2D(android.opengl.GLES20.GL_TEXTURE_2D, 0, 0, 0, bitmap);
			}
			else
			{
				android.opengl.GLUtils.texImage2D(android.opengl.GLES20.GL_TEXTURE_2D, 0, bitmap, 0);
			}
		@}

		extern(iOS)
		static IntPtr AllocPixelBuffer(int width, int height)
		{
			var size = width * height * 4;
			return extern<IntPtr>(size)"malloc( $0 )";
		}

		extern(iOS)
		static void FreePixelBuffer(IntPtr buffer)
		{
			extern(buffer)"free( $0 )";
		}

		[Foreign(Language.Java)]
		extern(Android)
		static Java.Object AllocPixelBuffer(int w, int h)
		@{
			return android.graphics.Bitmap.createBitmap(w, h, android.graphics.Bitmap.Config.ARGB_8888);
		@}

		[Foreign(Language.Java)]
		extern(Android)
		static void FreePixelBuffer(Java.Object bitmap)
		@{
			((android.graphics.Bitmap)bitmap).recycle();
		@}

	}
}
