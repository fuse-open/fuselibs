using Uno;
using Uno.Compiler.ExportTargetInterop;

namespace Experimental.TextureLoader
{
	[extern(CPLUSPLUS) Require("Source.Include", "@{Uno.Graphics.Texture2D:Include}")]
	[extern(CPLUSPLUS) Require("Source.Include", "@{Uno.Exception:Include}")]
	[extern(CPLUSPLUS) Require("Source.Include", "uBase/Buffer.h")]
	[extern(CPLUSPLUS) Require("Source.Include", "uBase/BufferStream.h")]
	[extern(CPLUSPLUS) Require("Source.Include", "uBase/Memory.h")]
	[extern(CPLUSPLUS) Require("Source.Include", "XliPlatform/GL.h")]
	[extern(CPLUSPLUS) Require("Source.Include", "uImage/Jpeg.h")]
	[extern(CPLUSPLUS) Require("Source.Include", "uImage/Png.h")]
	[extern(CPLUSPLUS) Require("Source.Include", "uImage/Texture.h")]
	[extern(CPLUSPLUS) Require("Source.Include", "Uno/Support.h")]
	static class TextureLoaderImpl
	{
		public static void JpegByteArrayToTexture2D(byte[] arr, Callback callback)
		{
			if defined(DOTNET)
			{
				CilTextureLoader.LoadTexture(arr, callback.Action, "fake.jpeg");
			}
			else if defined(CPLUSPLUS)
			@{
				try
				{
					uBase::Auto<uBase::BufferPtr> bp = new uBase::BufferPtr($0->Ptr(), $0->Length(), false);
					uBase::Auto<uBase::BufferStream> bs = new uBase::BufferStream(bp, true, false);
					uBase::Auto<uImage::ImageReader> ir = uImage::Jpeg::CreateReader(bs);
					uBase::Auto<uImage ::Bitmap> bmp = ir->ReadBitmap();
					int originalWidth = bmp->GetWidth(), originalHeight = bmp->GetHeight();

					int maxTextureSize;
					glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
					while (bmp->GetWidth() > maxTextureSize ||
						   bmp->GetHeight() > maxTextureSize)
					{
						bmp = bmp->DownSample2x2();
					}

					uBase::Auto<uImage::Texture> tex = uImage::Texture::Create(bmp);
					uGLTextureInfo info;

					GLuint handle = uCreateGLTexture(tex, false, &info);

					@{Experimental.TextureLoader.Callback.Execute(Uno.Graphics.Texture2D):Call($1, @{Uno.Graphics.Texture2D(OpenGL.GLTextureHandle,int2,int,Uno.Graphics.Format):New(handle, @{int2(int,int):New(originalWidth, originalHeight)}, info.MipCount, @{Uno.Graphics.Format.Unknown})})};
				}
				catch (const uBase::Exception &e)
				{
					U_THROW(@{Uno.Exception(string):New(uStringFromXliString(e.GetMessage()))});
				}
			@}
		}

		public static void PngByteArrayToTexture2D(byte[] arr, Callback callback)
		{
			if defined(DOTNET)
			{
				CilTextureLoader.LoadTexture(arr, callback.Action, "fake.png");
			}
			else if defined(CPLUSPLUS)
			@{
				try
				{
					uBase::Auto<uBase::BufferPtr> bp = new uBase::BufferPtr($0->Ptr(), $0->Length(), false);
					uBase::Auto<uBase::BufferStream> bs = new uBase::BufferStream(bp, true, false);
					uBase::Auto<uImage::ImageReader> ir = uImage::Png::CreateReader(bs);
					uBase::Auto<uImage::Bitmap> bmp = ir->ReadBitmap();
					int originalWidth = bmp->GetWidth(), originalHeight = bmp->GetHeight();

					int maxTextureSize;
					glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
					while (bmp->GetWidth() > maxTextureSize ||
						   bmp->GetHeight() > maxTextureSize)
					{
						bmp = bmp->DownSample2x2();
					}

					uBase::Auto<uImage::Texture> tex = uImage::Texture::Create(bmp);
					uGLTextureInfo info;
					GLuint handle = uCreateGLTexture(tex, false, &info);

					@{Experimental.TextureLoader.Callback.Execute(Uno.Graphics.Texture2D):Call($1, @{Uno.Graphics.Texture2D(OpenGL.GLTextureHandle,int2,int,Uno.Graphics.Format):New(handle, @{int2(int,int):New(originalWidth, originalHeight)}, info.MipCount, @{Uno.Graphics.Format.Unknown})})};
				}
				catch (const uBase::Exception &e)
				{
					U_THROW(@{Uno.Exception(string):New(uStringFromXliString(e.GetMessage()))});
				}
			@}
		}
	}
}
