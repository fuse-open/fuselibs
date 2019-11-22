using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.Platform;
using Uno.Collections;

namespace Experimental.TextureLoader
{
	public class InvalidContentTypeException : Exception
	{
		public InvalidContentTypeException(string reason) : base(reason) { }
	}

	public static class TextureLoader
	{
		[Obsolete("Use the returning overload instead")]
		public static void JpegByteArrayToTexture2D(byte[] arr, Uno.Action<texture2D> callback)
		{
			callback(JpegByteArrayToTexture2D(arr));
		}

		public static texture2D JpegByteArrayToTexture2D(byte[] arr)
		{
			try
			{
				return TextureLoaderImpl.JpegByteArrayToTexture2D(arr);
			}
			catch (Exception jpegException)
			{
				try
				{
					return TextureLoaderImpl.PngByteArrayToTexture2D(arr);
				}
				catch (Exception pngException)
				{
					// both threw, but since the user asked for JPEG, answer with the JPEG-error
					throw jpegException;
				}
			}
		}

		[Obsolete("Use the returning overload instead")]
		public static void PngByteArrayToTexture2D(byte[] arr, Uno.Action<texture2D> callback)
		{
			callback(PngByteArrayToTexture2D(arr));
		}

		public static texture2D PngByteArrayToTexture2D(byte[] arr)
		{
			try
			{
				return TextureLoaderImpl.PngByteArrayToTexture2D(arr);
			}
			catch (Exception pngException)
			{
				try
				{
					return TextureLoaderImpl.JpegByteArrayToTexture2D(arr);
				}
				catch (Exception jpegException)
				{
					// both threw, but since the user asked for PNG, answer with the PNG-error
					throw pngException;
				}
			}
		}

		[Obsolete("Use the returning overload instead")]
		public static void ByteArrayToTexture2DFilename(byte[] arr, string filename, Uno.Action<texture2D> callback)
		{
			callback(ByteArrayToTexture2DFilename(arr, filename));
		}

		public static texture2D ByteArrayToTexture2DFilename(byte[] arr, string filename)
		{
			filename = filename.ToLower();
			if (filename.EndsWith(".png"))
				return PngByteArrayToTexture2D(arr);
			else if (filename.EndsWith(".jpg") || filename.EndsWith(".jpeg"))
				return JpegByteArrayToTexture2D(arr);
			else
				throw new InvalidContentTypeException(filename);
		}

		[Obsolete("Use the returning overload instead")]
		public static void ByteArrayToTexture2DContentType(byte[] arr, string contentType, Uno.Action<texture2D> callback)
		{
			callback(ByteArrayToTexture2DContentType(arr, contentType));
		}

		public static texture2D ByteArrayToTexture2DContentType(byte[] arr, string contentType)
		{
			if (contentType.IndexOf("image/jpeg") != -1 || contentType.IndexOf("image/jpg") != -1)
				return JpegByteArrayToTexture2D(arr);
			else if (contentType.IndexOf("image/png") != -1)
				return PngByteArrayToTexture2D(arr);
			else if (contentType.IndexOf("application/octet-stream") != -1)
				return JpegByteArrayToTexture2D(arr);
			else if (contentType.IndexOf("binary/octet-stream") != -1)
				return JpegByteArrayToTexture2D(arr);
			else
				throw new InvalidContentTypeException(contentType);
		}
	}
}
