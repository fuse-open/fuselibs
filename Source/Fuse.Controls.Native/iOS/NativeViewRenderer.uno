using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.Graphics;
using OpenGL;

namespace Fuse.Controls.Native.iOS
{
	extern(iOS) internal class NativeViewRenderer : INativeViewRenderer
	{
		ObjC.Object _viewHandle;
		GLTextureHandle _textureHandle;
		IntPtr _pixelBuffer;
		bool _visualValid = false;

		public NativeViewRenderer(ObjC.Object viewHandle)
		{
			_viewHandle = viewHandle;
		}

		int2 _oldSize = int2(-1, -1);
		void INativeViewRenderer.Draw(
			float4x4 localToClipTransform,
			float2 position,
			float2 size,
			float density)
		{
			var realSize = (int2)(size * density);
			var reuse = true;

			if (_oldSize != realSize)
			{
				DeleteTexture();
				_textureHandle = GL.CreateTexture();
				_pixelBuffer = MallocPixelBuffer(realSize.X * realSize.Y * 4);
				_oldSize = realSize;
				reuse = false;
				_visualValid = false;
			}

			if (!_visualValid)
			{
				GL.BindTexture(GLTextureTarget.Texture2D, _textureHandle);
				Draw(_viewHandle, (int)_textureHandle, _pixelBuffer, realSize.X, realSize.Y, density, reuse);
				GL.BindTexture(GLTextureTarget.Texture2D, GLTextureHandle.Zero);
				_visualValid = true;
			}

			iOSBlitter.Singleton.Blit(
				new texture2D(_textureHandle, realSize, 1, Format.RGBA8888),
				position,
				size,
				localToClipTransform);
		}

		[Foreign(Language.ObjC)]
		[Require("Xcode.Framework", "GLKit")]
		[Require("Source.Include", "UIKit/UIKit.h")]
		[Require("Source.Include", "CoreGraphics/CoreGraphics.h")]
		[Require("Source.Include", "GLKit/GLKit.h")]
		[Require("Source.Include", "OpenGLES/EAGL.h")]
		[Require("Source.Include", "QuartzCore/QuartzCore.h")]
		static void Draw(
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
			CGColorSpaceRelease(colorSpace);

			[[view layer] renderInContext:context];

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

		void INativeViewRenderer.Invalidate()
		{
			_visualValid = false;
		}

		void DeleteTexture()
		{
			if (_textureHandle != GLTextureHandle.Zero)
			{
				GL.DeleteTexture(_textureHandle);
				_textureHandle = GLTextureHandle.Zero;
			}
			if (_pixelBuffer != IntPtr.Zero)
			{
				FreePixelBuffer(_pixelBuffer);
				_pixelBuffer = IntPtr.Zero;
			}
		}

		void IDisposable.Dispose()
		{
			DeleteTexture();
			_viewHandle = null;
		}

		[Foreign(Language.ObjC)]
		[Require("Source.Include", "UIKit/UIKit.h")]
		static void Show(ObjC.Object handle)
		@{
			::UIView* view = (::UIView*)handle;
			[view setHidden: false];
		@}

		[Foreign(Language.ObjC)]
		[Require("Source.Include", "UIKit/UIKit.h")]
		static void Hide(ObjC.Object handle)
		@{
			::UIView* view = (::UIView*)handle;
			[view setHidden: true];
		@}

		static IntPtr MallocPixelBuffer(int size)
		{
			return extern<IntPtr>(size)"malloc( $0 )";
		}

		static void FreePixelBuffer(IntPtr buffer)
		{
			extern(buffer)"free( $0 )";
		}

	}

	extern(iOS) class iOSBlitter
	{
		internal static iOSBlitter Singleton = new iOSBlitter();

		public void Blit(texture2D vt, float2 pos, float2 size, float4x4 localToClipTransform)
		{
			draw
			{
				apply Fuse.Drawing.PreMultipliedAlphaCompositing;

				CullFace : PolygonFace.None;
				DepthTestEnabled: false;
				float2[] verts: readonly new float2[] {

					float2(0,0),
					float2(1,0),
					float2(1,1),
					float2(0,0),
					float2(1,1),
					float2(0,1)
				};

				float2 v: vertex_attrib(verts);
				float2 LocalVertex: pos + v * size;
				ClipPosition: Vector.Transform(LocalVertex, localToClipTransform);
				float2 TexCoord: v;
				PixelColor: sample(vt, float2(TexCoord.X, 1.0f - TexCoord.Y), SamplerState.LinearClamp);
			};
		}
	}
}
