using Uno.Threading;
using Uno;
using Uno.IO;
using Uno.Compiler.ExportTargetInterop;
using System;

namespace Fuse.ImageTools
{
	using DotNetNative;

	extern (DOTNET) internal class DotNetImageUtils
	{
		private const string default_extension = "jpg";

		public static void GetImageFromBase64(string b64, Action<string> onSuccess, Action<string> onFail)
		{
			try
			{
				var asBytes = Convert.FromBase64String(b64);

				var stream = new MemoryStream(asBytes);
				DotNetImage outImage = DotNetImage.FromStream(stream);

				var path = TemporaryPath(default_extension);
				outImage.Save(path);
				onSuccess(path);
			} catch (Exception e)
			{
				onFail(e.Message);
			}
		}

		public static void GetBase64FromImage(string path, Action<string> onSuccess, Action<string> onFail)
		{
			try
			{
				var image = DotNetImage.FromFile(path);

				using (MemoryStream ms = new MemoryStream())
				{
					image.Save(ms, ImageFormat.Jpeg);
					byte[] imageBytes = ms.GetBuffer();
					onSuccess(Convert.ToBase64String(imageBytes));
				}
			} catch (Exception e)
			{
				onFail(e.Message);
			}
		}

		public static void GetImageFromBuffer(byte[] bytes, Action<string> onSuccess, Action<string> onFail)
		{
				try
				{
					var path = GetImageFromBufferSync(bytes);

					onSuccess(path);
				} catch (Exception e)
				{
					onFail(e.Message);
				}
		}

		public static string GetImageFromBufferSync(byte[] bytes)
		{
			var image = DotNetImage.FromStream(new MemoryStream(bytes));
			var extension = GetContentTypeForImageData(bytes);
			var path = TemporaryPath(extension);
			image.Save(path);
			return path;
		}

		public static void Resize(string path, int desiredWidth, int desiredHeight, int mode, Action<string> onSuccess, Action<string> onFail, bool inPlace)
		{
			try
			{
				var sourceBitmap = DotNetImage.FromFile(path);
				Bitmap scaledBitmap = null;
				Bitmap resultBitmap = null;

				float width = sourceBitmap.Width;
				float height = sourceBitmap.Height;
				float ratio;

				if((int)width == desiredWidth && (int)height == desiredHeight)
				{
					onSuccess(path);
					return;
				}
				using (MemoryStream ms = new MemoryStream())
				{

					switch(mode){
						case ResizeMode.ScaleAndCrop:
							ratio = 1.0f;
							if (width > height)
							{
								if (height > desiredHeight)
								{
									ratio = desiredHeight / height;
								} else if (width > desiredWidth)
								{
									ratio = desiredWidth / width;
								}
							} else
							{
								if (width > desiredWidth)
								{
									ratio = desiredWidth / width;
								} else if (height > desiredHeight)
								{
									ratio = desiredHeight / height;
								}
							}
							width *= ratio;
							height *= ratio;

							scaledBitmap = CreateBitmap(sourceBitmap, width, height);

							resultBitmap = CreateBitmap(
																					scaledBitmap,
																					Uno.Math.Min(desiredWidth, (int)width),
																					Uno.Math.Min(desiredHeight, (int)height),
																					Uno.Math.Max(0, (int)width/2 - desiredWidth/2),
																					Uno.Math.Max(0, (int)height/2 - desiredHeight/2));

							break;

						case ResizeMode.KeepAspect:
							if (width > desiredWidth)
							{
								ratio = desiredWidth / width;
								width *= ratio;
								height *= ratio;
							}
							if (height > desiredHeight)
							{
								ratio = desiredHeight / height;
								width *= ratio;
								height *= ratio;
							}
							resultBitmap = CreateBitmap(sourceBitmap, width, height);

							break;

						default:
							resultBitmap = CreateBitmap(sourceBitmap, desiredWidth, desiredHeight);
							break;
					}

					var lowerCaseType = Uno.IO.Path.GetExtension(path).ToLower();
					ImageFormat fmt = CompressFormatFromOptions(lowerCaseType);

					if(inPlace)
					{
						resultBitmap.Save(path);
						onSuccess(path);
					} else
					{
						var newPath = TemporaryPath(lowerCaseType);
						resultBitmap.Save(newPath, fmt);
						onSuccess(newPath);
					}
				}
			} catch (Exception e)
			{
				onFail(e.Message);
			}
		}

		public static void Crop(string path, int x, int y, int width, int height, Action<string> onSuccess, Action<string> onFail, bool inPlace)
		{
			try
			{
				var cropRect = new Rectangle(x, y, width, height);
				var src = DotNetImage.FromFile(path);
				var bitmap = new Bitmap(src);
				Bitmap croppedImage;

				using(var g = Graphics.FromImage(bitmap))
				{
					croppedImage = bitmap.Clone(cropRect, (PixelFormat)bitmap.PixelFormat);

					var lowerCaseType = Uno.IO.Path.GetExtension(path).ToLower();
					ImageFormat fmt = CompressFormatFromOptions(lowerCaseType);

					if(inPlace)
					{
						croppedImage.Save(path);
						onSuccess(path);
					} else
					{
						var newPath = TemporaryPath(lowerCaseType);
						croppedImage.Save(newPath, fmt);
						onSuccess(newPath);
					}
				}
			} catch (Exception e)
			{
				onFail(e.Message);
			}
		}

		public static Bitmap CreateBitmap(DotNetImage sourceBitmap, float desiredWidth, float desiredHeight, float x = 0, float y = 0)
		{
			var rect = new Rectangle((int)x, (int)y, (int)desiredWidth, (int)desiredHeight);
			var resultBitmap = new Bitmap((int)desiredWidth, (int)desiredHeight);
			var g = Graphics.FromImage(resultBitmap);
			g.InterpolationMode = InterpolationMode.HighQualityBicubic;
			g.DrawImage(sourceBitmap, rect);
			return resultBitmap;
		}

		public static int2 GetSize(Image inImage)
		{
			var size = new int[2] {0, 0};
			GetSizeInternal(inImage.Path, size);
			return int2(size[0], size[1]);
		}

		static void GetSizeInternal(string path, int[] values)
		{
			try{
				var inImage = DotNetImage.FromFile(path);
				values[0] = inImage.Width;
				values[1] = inImage.Height;
			}catch(Exception e){
			}
		}

		public static ImageFormat CompressFormatFromOptions(string lowerCaseType)
		{
			if( lowerCaseType.Contains("jpeg") || lowerCaseType.Contains("jpg") )
			{
				return ImageFormat.Jpeg;
			} else if(lowerCaseType.Contains("png") )
			{
				return ImageFormat.Png;
			} else
			{
				throw new Exception("Invalid image format");
			}
		}

		static string TemporaryPath(string extension)
		{
			var dir = DotNetNative.Path.GetTempPath ();
			var path = DotNetNative.Path.ChangeExtension(dir + DotNetNative.Path.GetRandomFileName(), extension);
			return path;
		}

		static string GetContentTypeForImageData(byte[] bytes) {
				int c = bytes[0];
				switch (c) {
					case 0xFF:
							return "jpg";
					case 0x89:
							return "png";
					default:
							return null;
				}
		}
	}
}
