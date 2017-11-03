using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.Graphics;
using OpenGL;

namespace Fuse.Controls.Native.iOS
{
	extern(iOS) internal static class HeifTextureLoader
	{
		public static Future<texture2D> Load(byte[] bytes)
		{
			return new UploadPromise(bytes);
		}

		[Require("Xcode.Framework", "GLKit")]
		[Require("Source.Include", "UIKit/UIKit.h")]
		[Require("Source.Include", "CoreGraphics/CoreGraphics.h")]
		[Require("Source.Include", "GLKit/GLKit.h")]
		class UploadPromise : Promise<texture2D>
		{
			byte[] _bytes;

			public UploadPromise(byte[] bytes) : base(UpdateManager.Dispatcher)
			{
				_bytes = bytes;
				GraphicsWorker.Dispatch(Upload)
			}

			void Upload()
			{
				var image = GetUIImage(_bytes);
				if (image == null)
				{
					Reject(new Exception("Could not decode image from bytes"));
					return;
				}

				var textureHandle = GL.CreateTexture();
				GL.BindTexture(GLTextureTarget.Texture2D, textureHandle);
				Upload(image);
				GL.BindTexture(GLTextureTarget.Texture2D, GLTextureHandle.Zero);

				var size = int2(GetWidth(image), GetHeight(image));
				var texture = new texture2D(textureHandle, size, 1, Format.RGBA8888);

				Resolve(texture);
			}

			[Foreign(Language.ObjC)]
			static ObjC.Object GetUIImage(byte[] bytes)
			@{
				NSData* imageData = [NSData dataWithBytes:(const void*)bytes.unoArray->Ptr() length:bytes.unoArray->Length()];
				return [UIImage imageWithData:imageData];
			@}

			[Foreign(Language.ObjC)]
			static int GetWidth(ObjC.Object image)
			@{
				return ((UIImage*)image).width;
			@}

			[Foreign(Language.ObjC)]
			static int GetHeight(ObjC.Object image)
			@{
				return ((UIImage*)image).height;
			@}

			[Foreign(Language.ObjC)]
			static void Upload(ObjC.Object imageHandle)
			@{
				UIImage* image = (UIImage*)imageHandle;
				GLubyte* pixels = (GLubyte*)malloc(image.width * image.height * 4);

				CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
				CGContextRef context = CGBitmapContextCreate(pixels,
					image.width,
					image.height,
					8,
					image.width * 4,
					colorSpace,
					kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);

				CGContextDrawImage(context, CGRectMake(0, 0, image.width, image.height), image.CGImage);

				glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
				glTexImage2D(
					GL_TEXTURE_2D,
					0,
					GL_RGBA,
					image.width,
					image.height,
					0,
					GL_RGBA,
					GL_UNSIGNED_BYTE,
					pixels);

				CGContextRelease(context);
				CGColorSpaceRelease(colorSpace);
				free(pixels);
			@}
		}
	}
}
