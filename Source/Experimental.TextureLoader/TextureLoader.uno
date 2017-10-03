using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.Platform;
using Uno.Collections;

namespace Experimental.TextureLoader
{
	[TargetSpecificImplementation]
	class Callback
	{
		Action<texture2D> _action;
		public Action<texture2D> Action { get { return _action; }}

		public Callback(Action<texture2D> action)
		{
			_action = action;
		}

		public void Execute(texture2D arg)
		{
			_action(arg);
		}
	}

	public class InvalidContentTypeException : Exception
	{
		public InvalidContentTypeException(string reason) : base(reason) { }
	}

	public static class TextureLoader
	{
		public static void JpegByteArrayToTexture2D(Buffer arr, Uno.Action<texture2D> callback)
		{
			try
			{
				TextureLoaderImpl.JpegByteArrayToTexture2D(arr, new Callback(callback));
			}
			catch (Exception jpegException)
			{
				try
				{
					TextureLoaderImpl.PngByteArrayToTexture2D(arr, new Callback(callback));
				}
				catch (Exception pngException)
				{
					// both threw, but since the user asked for JPEG, answer with the JPEG-error
					throw jpegException;
				}
			}
		}

		public static void PngByteArrayToTexture2D(Buffer arr, Uno.Action<texture2D> callback)
		{
			try
			{
				TextureLoaderImpl.PngByteArrayToTexture2D(arr, new Callback(callback));
			}
			catch (Exception pngException)
			{
				try
				{
					TextureLoaderImpl.JpegByteArrayToTexture2D(arr, new Callback(callback));
				}
				catch (Exception jpegException)
				{
					// both threw, but since the user asked for PNG, answer with the PNG-error
					throw pngException;
				}
			}
		}

		public static void ByteArrayToTexture2DFilename(Buffer arr, string filename, Uno.Action<texture2D> callback)
		{
			filename = filename.ToLower();
			if (filename.EndsWith(".png"))
				PngByteArrayToTexture2D(arr, callback);
			else if (filename.EndsWith(".jpg") || filename.EndsWith(".jpeg"))
				JpegByteArrayToTexture2D(arr, callback);
			else
				throw new InvalidContentTypeException(filename);
		}

		public static void ByteArrayToTexture2DContentType(Buffer arr, string contentType, Uno.Action<texture2D> callback)
		{
			if (contentType.IndexOf("image/jpeg") != -1 || contentType.IndexOf("image/jpg") != -1)
				JpegByteArrayToTexture2D(arr, callback);
			else if (contentType.IndexOf("image/png") != -1)
				PngByteArrayToTexture2D(arr, callback);
			else if (contentType.IndexOf("application/octet-stream") != -1)
				JpegByteArrayToTexture2D(arr, callback);
			else
				throw new InvalidContentTypeException(contentType);
		}
	}
}
