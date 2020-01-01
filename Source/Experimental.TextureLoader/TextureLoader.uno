using Uno;
using Uno.Graphics.Utils;

namespace Experimental.TextureLoader
{
	[Obsolete]
	public class InvalidContentTypeException : Exception
	{
		public InvalidContentTypeException(string reason) : base(reason) { }
	}

	[Obsolete]
	public static class TextureLoader
	{
		[Obsolete("Use the returning overload instead")]
		public static void JpegByteArrayToTexture2D(byte[] arr, Uno.Action<texture2D> callback)
		{
			callback(JpegByteArrayToTexture2D(arr));
		}

		[Obsolete]
		public static texture2D JpegByteArrayToTexture2D(byte[] arr)
		{
			return Uno.Graphics.Utils.TextureLoader.Load2DJpeg(arr);
		}

		[Obsolete("Use the returning overload instead")]
		public static void PngByteArrayToTexture2D(byte[] arr, Uno.Action<texture2D> callback)
		{
			callback(PngByteArrayToTexture2D(arr));
		}

		[Obsolete]
		public static texture2D PngByteArrayToTexture2D(byte[] arr)
		{
			return Uno.Graphics.Utils.TextureLoader.Load2DPng(arr);
		}

		[Obsolete("Use the returning overload instead")]
		public static void ByteArrayToTexture2DFilename(byte[] arr, string filename, Uno.Action<texture2D> callback)
		{
			callback(ByteArrayToTexture2DFilename(arr, filename));
		}

		[Obsolete]
		public static texture2D ByteArrayToTexture2DFilename(byte[] arr, string filename)
		{
			return Uno.Graphics.Utils.TextureLoader.Load2D(filename, arr);
		}

		[Obsolete("Use the returning overload instead")]
		public static void ByteArrayToTexture2DContentType(byte[] arr, string contentType, Uno.Action<texture2D> callback)
		{
			callback(ByteArrayToTexture2DContentType(arr, contentType));
		}

		[Obsolete]
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
