using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.Graphics;
using Uno.IO;
using Uno.UX;
using OpenGL;

namespace System.Drawing
{
	[DotNetType]
	extern(CIL) public abstract class Image
	{
		public extern int Width { get; }
		public extern int Height { get; }
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
	}
}

namespace Fuse.Internal.Bitmaps
{
	[ForeignInclude(Language.Java, "android.graphics.Bitmap", "android.graphics.BitmapFactory", "android.opengl.GLES20", "android.opengl.GLUtils", "java.io.InputStream", "java.nio.ByteBuffer", "com.fuse.android.ByteBufferInputStream")]
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
			ByteBufferInputStream inputStream = new ByteBufferInputStream((ByteBuffer)byteBuffer);
			return BitmapFactory.decodeStream(inputStream);
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

	[Require("Header.Include", "uBase/BufferStream.h")]
	[Require("Header.Include", "uImage/Bitmap.h")]
	[Require("Header.Include", "uImage/Png.h")]
	[Require("Header.Include", "uImage/Jpeg.h")]
	[Require("Header.Include", "Uno/Support.h")]
	extern(!Android && CPLUSPLUS) static class CPlusPlusHelpers
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
	}

	[extern(CPLUSPLUS) Require("Header.Include", "uImage/Bitmap.h")]
	public sealed class Bitmap : IDisposable
	{
		public void Dispose()
		{
			if defined(Android)
				AndroidHelpers.Recycle(NativeBitmap);
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

		extern(CIL) public readonly System.Drawing.Bitmap NativeBitmap;
		extern(CIL) protected Bitmap(System.Drawing.Bitmap nativeBitmap)
		{
			NativeBitmap = nativeBitmap;
			_size = new int2(nativeBitmap.Width, nativeBitmap.Height);
		}

		extern(!Android && CPLUSPLUS) internal readonly CPlusPlusHelpers.NativeBitmapHandle NativeBitmap;
		extern(!Android && CPLUSPLUS) protected Bitmap(CPlusPlusHelpers.NativeBitmapHandle nativeBitmap)
		{
			NativeBitmap = nativeBitmap;
			_size = CPlusPlusHelpers.GetSize(nativeBitmap);
		}

		static Bitmap LoadFromBundleFile(BundleFile bundleFile)
		{
			if defined(CIL)
				return LoadFromStream(bundleFile.OpenRead());
			else if defined(Android)
			{
				var nativeBitmap = AndroidHelpers.DecodeFromBundle(bundleFile.BundlePath);
				return new Bitmap(nativeBitmap);
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

		public float4 GetPixel(int x, int y)
		{
			if (x < 0 || x >= Size.X)
				throw new ArgumentOutOfRangeException(nameof(x));
			if (y < 0 || y >= Size.Y)
				throw new ArgumentOutOfRangeException(nameof(y));

			if defined(Android)
			{
				var color = AndroidHelpers.GetPixel(NativeBitmap, x, y);
				return Color.FromARGB(color);
			}
			else if defined(CIL)
			{
				var color = NativeBitmap.GetPixel(x, y);
				return float4(color.R / 255.0f, color.G / 255.0f, color.B / 255.0f, color.A / 255.0f);
			}
			else if defined(CPLUSPLUS)
			{
				var color = CPlusPlusHelpers.ReadPixel(NativeBitmap, x, y);
				return Color.FromARGB(color);
			}
			else
				build_error;
		}
	}
}
