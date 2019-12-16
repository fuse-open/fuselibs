using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.Native.Textures;
using Uno.Runtime.InteropServices;
using OpenGL;

namespace Experimental.TextureLoader
{
	extern(DOTNET) static class CilTextureLoader
	{
		public static texture2D LoadTexture(byte[] buffer, string filename)
		{
			using(var stream = new Uno.IO.MemoryStream())
			{
				var imageBytes = buffer;
				stream.Write(imageBytes, 0, imageBytes.Length);
				stream.Position = 0;

				using(var bitmap = new Texture(filename, stream))
				{
					if (bitmap.TextureType != TextureType.Texture2D)
					throw new Exception("Input is not a 2D image");

					GLPixelFormat internalFormat, pixelFormat;
					GLPixelType pixelType;
					Uno.Graphics.Format format;
					switch (bitmap.PixelFormat)
					{
						case PixelFormat.RGBA_8_8_8_8_UInt_Normalize:
						internalFormat = GLPixelFormat.Rgba;
						pixelFormat = GLPixelFormat.Rgba;
						pixelType = GLPixelType.UnsignedByte;
						format = Uno.Graphics.Format.RGBA8888;
						break;

						case PixelFormat.RGB_8_8_8_UInt_Normalize:
						internalFormat = GLPixelFormat.Rgb;
						pixelFormat = GLPixelFormat.Rgb;
						pixelType = GLPixelType.UnsignedByte;
						format = Uno.Graphics.Format.Unknown;
						break;

						case PixelFormat.LA_8_8_UInt_Normalize:
						internalFormat = GLPixelFormat.LuminanceAlpha;
						pixelFormat = GLPixelFormat.LuminanceAlpha;
						pixelType = GLPixelType.UnsignedByte;
						format = Uno.Graphics.Format.LA88;
						break;

						case PixelFormat.L_8_UInt_Normalize:
						internalFormat = GLPixelFormat.Luminance;
						pixelFormat = GLPixelFormat.Luminance;
						pixelType = GLPixelType.UnsignedByte;
						format = Uno.Graphics.Format.L8;
						break;

						default:
						throw new Exception("Unhandled PixelFormat: " + bitmap.PixelFormat);
					}

					var textureHandle = GL.CreateTexture();
					GL.BindTexture(GLTextureTarget.Texture2D, textureHandle);
					GL.PixelStore(GLPixelStoreParameter.UnpackAlignment, 1);
					var dataPin = GCHandle.Alloc(bitmap.ReadData(), GCHandleType.Pinned);
					GL.TexImage2D(GLTextureTarget.Texture2D, 0, internalFormat, bitmap.Width, bitmap.Height, 0, pixelFormat, pixelType, dataPin.AddrOfPinnedObject());
					dataPin.Free();
					return new Uno.Graphics.Texture2D(textureHandle, new Uno.Int2(bitmap.Width, bitmap.Height), 1, format);
				}
			}

			// Workaround for false E4516: Not all code paths return a value
			return null;
		}
	}
}
