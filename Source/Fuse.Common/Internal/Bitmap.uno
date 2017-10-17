using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.Graphics;
using Uno.IO;
using Uno.UX;
using OpenGL;
using Fuse.Platform;

namespace System.Drawing
{
	[DotNetType("System.Array")]
	public extern(CIL) class CilArray
	{
	}

	[DotNetType("System.Runtime.InteropServices.Marshal")]
	public extern(CIL) static class Marshal
	{
		public static extern IntPtr UnsafeAddrOfPinnedArrayElement(CilArray arr, int index);
		public static extern void Copy(IntPtr source, byte[] destination, int start, int length);
	}

	[DotNetType]
	extern(CIL) public abstract class Image
	{
		public extern int Width { get; }
		public extern int Height { get; }
		public extern int Flags { get; }
		public extern PixelFormat PixelFormat { get; }
	}

	[DotNetType, TargetSpecificType]
	extern(CIL) public struct Color
	{
		public extern byte R { get; }
		public extern byte G { get; }
		public extern byte B { get; }
		public extern byte A { get; }
	}

	[DotNetType]
	extern(CIL) public sealed class Bitmap : Image
	{
		public extern Bitmap(Uno.IO.Stream stream);
		public extern Color GetPixel(int x, int y);
		public extern BitmapData LockBits( Rectangle rect, ImageLockMode flags, PixelFormat format );
		public extern void UnlockBits(BitmapData bitmapdata);
	}

	[DotNetType("System.Drawing.Rectangle")]
	public extern(DOTNET) struct Rectangle
	{
		public extern Rectangle(int a, int b, int x, int y);
		public extern int Height { get; set; }
		public extern int Width { get; set; }
	}

	[DotNetType("System.Drawing.Imaging.ImageLockMode")]
	public extern(DOTNET) enum ImageLockMode
	{
		ReadOnly = 1
	}

	[DotNetType("System.Drawing.Imaging.PixelFormat")]
	public extern(DOTNET) enum PixelFormat
	{
		Format32bppArgb = 2498570,
		Format32bppPArgb = 925707,
		Format32bppRgb = 139273,
		PAlpha = 524288,
		Alpha = 262144
	}

	[DotNetType("System.Drawing.Imaging.BitmapData")]
	public extern(DOTNET) class BitmapData
	{
		public extern int Height { get; set; }
		public extern PixelFormat PixelFormat { get; set; }
		public extern IntPtr Scan0 { get; set; }
		public extern int Stride { get; set; }
		public extern int Width { get; set; }
	}

	namespace Imaging {
		[DotNetType]
		extern(CIL) public enum ImageFlags
		{
			ColorSpaceCmyk = 32,
			ColorSpaceYcck = 256
		} 
	}
}


namespace Fuse.Internal.Bitmaps
{
	[ForeignInclude(Language.Java, "android.graphics.Bitmap", "android.graphics.BitmapFactory", "android.opengl.GLES20", "android.opengl.GLUtils", "java.io.InputStream", "java.nio.ByteBuffer", "com.fuse.android.ByteBufferInputStream", "com.fuse.android.RawByteBufferInputStream")]
	extern(Android) static class AndroidHelpers
	{
		[Foreign(Language.Java)]
		public static void Recycle(Java.Object bitmap)
		@{
			((Bitmap)bitmap).recycle();
		@}

		[Foreign(Language.Java)]
		public static Java.Object DecodeFromBundle(string pathName)
		@{
			try
			{
				InputStream stream = com.fuse.Activity.getRootActivity().getAssets().open(pathName);
				return android.graphics.BitmapFactory.decodeStream(stream);
			}
			catch (Exception e)
			{
				e.printStackTrace();
				return null;
			}
		@}

		[Foreign(Language.Java)]
		public static Java.Object DecodeFromByteBuffer(Java.Object byteBuffer)
		@{
			RawByteBufferInputStream inputStream = new RawByteBufferInputStream((ByteBuffer)byteBuffer);
			return BitmapFactory.decodeStream(inputStream);
		@}

		[Foreign(Language.Java)]
		public static void TexImage2D(int level, Java.Object bitmap, int border)
		@{
			GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, level, (Bitmap)bitmap, border);
		@}

		[Foreign(Language.Java)]
		static int GetWidth(Java.Object bitmap)
		@{
			return ((Bitmap)bitmap).getWidth();
		@}

		[Foreign(Language.Java)]
		static int GetHeight(Java.Object bitmap)
		@{
			return ((Bitmap)bitmap).getHeight();
		@}

		public static int2 GetSize(Java.Object bitmap)
		{
			return new int2(GetWidth(bitmap), GetHeight(bitmap));
		}

		[Foreign(Language.Java)]
		public static int GetPixel(Java.Object bitmap, int x, int y)
		@{
			return ((Bitmap)bitmap).getPixel(x, y);
		@}
	}

	[ForeignInclude(Language.ObjC, "ImageIO/ImageIO.h")]
	[Require("Xcode.Framework", "ImageIO")]
	[Require("Xcode.Framework","CoreGraphics")]
	[Require("Source.Include", "CoreGraphicsLib.h")]
	[Require("Xcode.Framework","GLKit")]
	[extern(OSX) Require("Source.Include","XliPlatform/GL.h")]
	[extern(iOS) Require("Source.Include","OpenGLES/ES2/gl.h")]
	extern(iOS) static class IOSHelpers
	{
		[Foreign(Language.ObjC)]
		public static IntPtr CreateImageFromBundlePath(string path)
		@{
			NSURL* url = [[NSBundle bundleForClass:[StrongUnoObject class]] URLForResource:path withExtension:@""];
			CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
			return CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
		@}

		[Foreign(Language.ObjC)]
		public static IntPtr CreateImageFromByteArray(byte[] bytes)
		@{
			CFDataRef data = CFDataCreateWithBytesNoCopy(NULL, (const UInt8 *)bytes.unoArray->Ptr(), bytes.unoArray->Length(), kCFAllocatorNull);
			CGImageSourceRef imageSource = CGImageSourceCreateWithData(data, NULL);
			return CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
		@}

		[Foreign(Language.ObjC)]
		public static void ReleaseImage(IntPtr image)
		@{
			CGImageRelease((CGImageRef)image);
		@}

		[Foreign(Language.ObjC)]
		static int GetWidth(IntPtr image)
		@{
			return CGImageGetWidth((CGImageRef)image);
		@}

		[Foreign(Language.ObjC)]
		static int GetHeight(IntPtr image)
		@{
			return CGImageGetHeight((CGImageRef)image);
		@}

		public static int2 GetSize(IntPtr image)
		{
			return new int2(GetWidth(image), GetHeight(image));
		}

		[Foreign(Language.ObjC)]
		public static int ReadPixel(IntPtr image, int x, int y)
		@{
			CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider((CGImageRef)image));
			int pitch = CGImageGetBytesPerRow((CGImageRef)image);
			CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo((CGImageRef)image);

			const UInt8* data = CFDataGetBytePtr(pixelData);
			const UInt8* pixel = data + pitch * y + x * 4;
			int r = pixel[0];
			int g = pixel[1];
			int b = pixel[2];
			int a = pixel[3];

			CFRelease(pixelData);

			return b | (g << 8) | (r << 16) | (a << 24); // encode as 0xAARRGGBB
		@}

		[Foreign(Language.CPlusPlus)]
		public static void UploadTexture(IntPtr image, int textureHandle)
		@{
			@autoreleasepool 
			{
				CGImageRef imageRef = (CGImageRef)image;
				CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider(imageRef));
				int width = CGImageGetWidth(imageRef);
				int height = CGImageGetHeight(imageRef);

				const UInt8* data = CFDataGetBytePtr(pixelData);

				glBindTexture(GL_TEXTURE_2D, textureHandle);
				glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height,
					0, GL_RGBA, GL_UNSIGNED_BYTE, data);
			}
		@}
	}

	[Require("Header.Include", "uBase/BufferStream.h")]
	[Require("Header.Include", "uImage/Bitmap.h")]
	[Require("Header.Include", "uImage/Png.h")]
	[Require("Header.Include", "uImage/Jpeg.h")]
	[Require("Header.Include", "uImage/Texture.h")]
	[Require("Header.Include", "Uno/Support.h")]
	[Require("Header.Include", "XliPlatform/GL.h")]
	extern(!Android && !iOS && CPLUSPLUS) static class CPlusPlusHelpers
	{
		[TargetSpecificType]
		[Set("TypeName", "uImage::Bitmap*")]
		[Set("DefaultValue", "NULL")]
		extern(CPLUSPLUS) internal struct NativeBitmapHandle
		{
		}

		[TargetSpecificType]
		[Set("TypeName", "uBase::Stream*")]
		[Set("DefaultValue", "NULL")]
		extern(CPLUSPLUS) internal struct NativeStreamHandle
		{
		}

		public static NativeStreamHandle NativeStreamFromCppXliStream(CppXliStream stream)
		@{
			return stream->_handle;
		@}

		static NativeBitmapHandle LoadPNGFromStream(NativeStreamHandle stream)
		@{
			try
			{
				uBase::Auto<uImage::ImageReader> ir = uImage::Png::CreateReader(stream);
				return ir->ReadBitmap();
			}
			catch (const uBase::Exception &e)
			{
				U_THROW(@{Uno.Exception(string):New(uStringFromXliString(e.GetMessage()))});
			}
		@}

		static NativeBitmapHandle LoadJPGFromStream(NativeStreamHandle stream)
		@{
			try
			{
				uBase::Auto<uImage::ImageReader> ir = uImage::Jpeg::CreateReader(stream);
				return ir->ReadBitmap();
			}
			catch (const uBase::Exception &e)
			{
				U_THROW(@{Uno.Exception(string):New(uStringFromXliString(e.GetMessage()))});
			}
		@}

		static CPlusPlusHelpers.NativeBitmapHandle LoadFromNativeStream(string pathHint, NativeStreamHandle stream)
		{
			if (pathHint.ToLower().EndsWith(".png"))
			{
				try
				{
					return LoadPNGFromStream(stream);
				}
				catch (Exception outerException)
				{
					try
					{
						return LoadJPGFromStream(stream);
					}
					catch (Exception innerException)
					{
						 // both threw, but since the user asked for PNG, answer with the PNG-error
						throw outerException;
					}
				}
			}
			else
			{
				try
				{
					return LoadJPGFromStream(stream);
				}
				catch (Exception outerException)
				{
					try
					{
						return LoadPNGFromStream(stream);
					}
					catch (Exception innerException)
					{
						 // both threw, but since the user asked for JPEG, answer with the JPEG-error
						throw outerException;
					}
				}
			}
		}

		public static CPlusPlusHelpers.NativeBitmapHandle LoadFromByteArray(string pathHint, byte[] bytes)
		@{
			uBase::Auto<uBase::BufferPtr> buffer = new uBase::BufferPtr(bytes->Ptr(), bytes->Length(), false);
			uBase::Auto<uBase::BufferStream> stream = new uBase::BufferStream(buffer, true, false);
			return @{CPlusPlusHelpers.LoadFromNativeStream(string, NativeStreamHandle):Call(pathHint, stream)};
		@}

		public static CPlusPlusHelpers.NativeBitmapHandle LoadFromXliStream(string pathHint, CppXliStream stream)
		{
			var nativeStream = extern<NativeStreamHandle>(stream)"$0->_handle";
			return LoadFromNativeStream(pathHint, nativeStream);
		}

		static int GetWidth(NativeBitmapHandle nativeBitmap)
		@{
			return nativeBitmap->GetWidth();
		@}

		static int GetHeight(NativeBitmapHandle nativeBitmap)
		@{
			return nativeBitmap->GetHeight();
		@}

		public static int2 GetSize(NativeBitmapHandle nativeBitmap)
		{
			return new int2(GetWidth(nativeBitmap), GetHeight(nativeBitmap));
		}

		public static int ReadPixel(NativeBitmapHandle nativeBitmap, int x, int y)
		@{
			uBase::Vector4u8 color = nativeBitmap->GetPixelColor(x, y);
			return color.Z | (color.Y << 8) | (color.X << 16) | (color.W << 24); // encode as 0xAARRGGBB
		@}

		public static GLTextureHandle UploadTexture(NativeBitmapHandle nativeBitmap)
		@{
			uImage::Texture* texture = uImage::Texture::Create(nativeBitmap);
			return uCreateGLTexture(texture, true, NULL);
		@}
	}

	[extern(CPLUSPLUS) Require("Header.Include", "uImage/Bitmap.h")]
	public sealed class Bitmap : IDisposable
	{
		public void Dispose()
		{
			if defined(Android)
				AndroidHelpers.Recycle(NativeBitmap);
			else if defined(iOS)
				IOSHelpers.ReleaseImage(NativeImage);
			else
				build_error; // TODO!
		}

		readonly int2 _size;
		public int2 Size { get { return _size; } }

		extern(Android) public readonly Java.Object NativeBitmap;
		extern(Android) protected Bitmap(Java.Object nativeBitmap)
		{
			NativeBitmap = nativeBitmap;
			_size = AndroidHelpers.GetSize(nativeBitmap);
		}

		extern(iOS) public readonly IntPtr NativeImage;
		extern(iOS) protected Bitmap(IntPtr nativeImage)
		{
			NativeImage = nativeImage;
			_size = IOSHelpers.GetSize(nativeImage);
		}

		extern(CIL) public readonly System.Drawing.Bitmap NativeBitmap;
		extern(CIL) protected Bitmap(System.Drawing.Bitmap nativeBitmap)
		{
			NativeBitmap = nativeBitmap;
			_size = new int2(nativeBitmap.Width, nativeBitmap.Height);
		}

		extern(!Android && !iOS && CPLUSPLUS) internal readonly CPlusPlusHelpers.NativeBitmapHandle NativeBitmap;
		extern(!Android && !iOS && CPLUSPLUS) protected Bitmap(CPlusPlusHelpers.NativeBitmapHandle nativeBitmap)
		{
			NativeBitmap = nativeBitmap;
			_size = CPlusPlusHelpers.GetSize(nativeBitmap);
		}

		static Bitmap LoadFromBundleFile(BundleFile bundleFile)
		{
			if (bundleFile.BundlePath.EndsWith(".gif"))
			{
				Fuse.Diagnostics.UserWarning("Gif files are not supported!", bundleFile);
			}

			if defined(CIL)
				return LoadFromStream(bundleFile.OpenRead());
			else if defined(Android)
			{
				var nativeBitmap = AndroidHelpers.DecodeFromBundle(bundleFile.BundlePath);
				return new Bitmap(nativeBitmap);
			}
			else if defined(iOS)
			{
				var nativeImage = IOSHelpers.CreateImageFromBundlePath("data/" + bundleFile.BundlePath);
				return new Bitmap(nativeImage);
			}
			else if defined(CPLUSPLUS)
			{
				var stream = (CppXliStream)bundleFile.OpenRead();
				var nativeBitmap = CPlusPlusHelpers.LoadFromXliStream(bundleFile.Name, stream);
				return new Bitmap(nativeBitmap);
			}
			else
				build_error;
		}

		extern(CPLUSPLUS) static Bitmap LoadFromByteArray(string pathHint, byte[] data)
		{
			if defined(Android)
			{
				var byteBuffer = Android.Base.Wrappers.JWrapper.Wrap(Android.Base.Types.ByteBuffer.NewDirectByteBuffer(data));
				var nativeBitmap = AndroidHelpers.DecodeFromByteBuffer(byteBuffer);
				return new Bitmap(nativeBitmap);
			}
			else if defined(iOS)
			{
				var nativeImage = IOSHelpers.CreateImageFromByteArray(data);
				return new Bitmap(nativeImage);
			}
			else
			{
				var nativeBitmap = CPlusPlusHelpers.LoadFromByteArray(pathHint, data);
				return new Bitmap(nativeBitmap);
			}
		}

		static extern(CIL) Bitmap LoadFromStream(Stream stream)
		{
			var nativeBitmap = new System.Drawing.Bitmap(stream);
			return new Bitmap(nativeBitmap);
		}

		public static Bitmap LoadFromFileSource(FileSource fileSource)
		{
			var bundleFileSource = fileSource as BundleFileSource;
			if (bundleFileSource != null)
				return LoadFromBundleFile(bundleFileSource.BundleFile);

			if defined(CIL)
				return LoadFromStream(fileSource.OpenRead());
			else if defined(CPLUSPLUS)
			{
				var data = fileSource.ReadAllBytes();
				return LoadFromByteArray(fileSource.Name, data);
			}
			else
				build_error;
		}

		public static Bitmap LoadFromBuffer(Buffer buffer, String contentType)
		{
			if defined(CIL) 
			{
				var stream = new MemoryStream(buffer.GetHandle, false);
				return LoadFromStream(stream);
			}
			else if defined(CPLUSPLUS)
				return LoadFromByteArray(contentType, buffer.GetHandle);
			else
				build_error;
		}

		public float4 GetPixel(int x, int y)
		{
			if (x < 0 || x >= Size.X)
				throw new ArgumentOutOfRangeException(nameof(x));
			if (y < 0 || y >= Size.Y)
				throw new ArgumentOutOfRangeException(nameof(y));

			if defined(Android)
			{
				var color = AndroidHelpers.GetPixel(NativeBitmap, x, y);
				return Color.FromArgb((uint)color);
			}
			else if defined(iOS)
			{
				var color = IOSHelpers.ReadPixel(NativeImage, x, y);
				return Color.FromArgb((uint)color);
			}
			else if defined(CIL)
			{
				var color = NativeBitmap.GetPixel(x, y);
				if (IsCMYK(NativeBitmap)){
					return FromCmyk(color);
				}

				return float4(color.R / 255.0f, color.G / 255.0f, color.B / 255.0f, color.A / 255.0f);
			}
			else if defined(CPLUSPLUS)
			{
				var color = CPlusPlusHelpers.ReadPixel(NativeBitmap, x, y);
				return Color.FromArgb((uint)color);
			}
			else
				build_error;
		}

		extern(CIL) static bool IsCMYK(System.Drawing.Image image)
		{
			var flags = (System.Drawing.Imaging.ImageFlags)image.Flags;
			if (flags.HasFlag(System.Drawing.Imaging.ImageFlags.ColorSpaceCmyk) || flags.HasFlag(System.Drawing.Imaging.ImageFlags.ColorSpaceYcck))
			{
				return true;
			}

			const int PixelFormat32bppCMYK = (15 | (32 << 8));
			return (int)image.PixelFormat == PixelFormat32bppCMYK;
		}

		extern(CIL) static float4 FromCmyk (System.Drawing.Color color)
		{
			var C = color.R / 255.0f; 
			var K = color.G / 255.0f;
			var M = color.B / 255.0f;
			var Y = color.A / 255.0f;

			return float4((1 - C) * (1 - K), (1 - M) * (1 - K), (1 - Y) * (1 - K), 1);
		}

		extern(CIL) static void Render(System.Drawing.Bitmap nativeBitmap, OpenGL.GLTextureHandle textureHandle)
		{
			System.Drawing.Rectangle rect = new System.Drawing.Rectangle(0, 0, nativeBitmap.Width, nativeBitmap.Height);
			var bitmapData = nativeBitmap.LockBits(rect, System.Drawing.ImageLockMode.ReadOnly, System.Drawing.PixelFormat.Format32bppPArgb);
			IntPtr ptr = bitmapData.Scan0;
			int bytes  = Math.Abs(bitmapData.Stride) * nativeBitmap.Height;
			byte[] rgbValues = new byte[bytes];
			byte[] outputValues = new byte[bytes];

			System.Drawing.Marshal.Copy(ptr, rgbValues, 0, bytes);

			// copy the bulk of pixels
			for (var i = 0; i < bytes; i += 1)
			{
				outputValues[i] = rgbValues[i];
			}

			// swap R and B
			for (var i = 0; i < bytes; i += 4)
			{
				outputValues[i + 2] = rgbValues[i];
				outputValues[i] = rgbValues[i + 2];
			}

			GL.BindTexture(GLTextureTarget.Texture2D, textureHandle);
			GL.TexImage2D(
				GLTextureTarget.Texture2D, 0, 
				GLPixelFormat.Rgba, (int)nativeBitmap.Width, (int)nativeBitmap.Height, 0, 
				GLPixelFormat.Rgba, GLPixelType.UnsignedByte, 
				new Buffer(outputValues)
			);
			nativeBitmap.UnlockBits(bitmapData);
		}

		// TODO: consider making this an extension method somewhere else instead?
		public static Texture2D UploadTexture(Bitmap bitmap)
		{
			if defined(Android)
			{
				var textureHandle = GL.CreateTexture();
				// TODO: bind texture
				AndroidHelpers.TexImage2D(0, bitmap.NativeBitmap, 0);
				return new Texture2D(textureHandle, bitmap.Size, 1, Format.RGBA8888);
			}
			else if defined(CIL)
			{
				var textureHandle = GL.CreateTexture();
				Render(bitmap.NativeBitmap, textureHandle);
				return new Texture2D(textureHandle, bitmap.Size, 1, Format.RGBA8888);
			}
			else if defined (iOS)
			{
				var textureHandle = GL.CreateTexture();
				IOSHelpers.UploadTexture(bitmap.NativeImage, (int)textureHandle);
				return new Texture2D(textureHandle, bitmap.Size, 1, Format.RGBA8888);
			}
			else if defined (CPLUSPLUS)
			{
				var textureHandle = CPlusPlusHelpers.UploadTexture(bitmap.NativeBitmap);
				return new Texture2D(textureHandle, bitmap.Size, 1, Format.RGBA8888);
			}
			else 
			{
				build_error;
			}
		}
	}
}
