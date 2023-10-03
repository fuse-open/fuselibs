using Uno;
using Uno.Graphics;
using Uno.UX;
using Uno.IO;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Uno.Graphics.Utils;
using Fuse.Resources.Exif;

namespace Fuse.Resources
{
	internal class ImageBackgroundLoad
	{
		Action<texture2D, byte[], ImageOrientation> _done;
		Action<Exception> _fail;
		Exception _exception;
		ImageOrientation _orientation;
		texture2D _tex;
		byte[] _bytes;
		int2 _targetSize;
		string _filename;
		bool _diskCache = false;
		FileSource _filesource;

		public ImageBackgroundLoad(FileSource filesource, int2 targetSize, Action<texture2D, byte[], ImageOrientation> done, Action<Exception> fail)
		{
			_filesource = filesource;
			_filename = _filesource.Name;
			_targetSize = targetSize;
			_done = done;
			_fail = fail;
		}

		public ImageBackgroundLoad(string filename, byte[] data, bool diskCache, int2 targetSize, Action<texture2D, byte[], ImageOrientation> done, Action<Exception> fail)
		{
			_filename = filename;
			_targetSize = targetSize;
			_bytes = data;
			_diskCache = diskCache;
			_done = done;
			_fail = fail;
		}

		public void Dispatch()
		{
			GraphicsWorker.Dispatch(RunTask);
		}

		void ReadBytes()
		{
			if (_bytes == null)
			{
				if (_filesource == null)
					_bytes = File.ReadAllBytes(_filename);
				else
					_bytes = _filesource.ReadAllBytes();
			}
		}

		void RunTask()
		{
			try
			{
				ReadBytes();
				_orientation = ExifData.FromByteArray(_bytes).Orientation;
				_bytes = ResizeImage(_bytes, _targetSize);
				_tex = TextureLoader.Load2D(_filename, _bytes);
				if (_diskCache)
					File.WriteAllBytes(_filename, _bytes);
				if defined(OpenGL)
					OpenGL.GL.Finish();
				UpdateManager.PostAction(UIDoneCallback);
			}
			catch (Exception e)
			{
				_exception = e;
				UpdateManager.AddOnceAction(UIFailCallback);
			}
		}

		void UIDoneCallback()
		{
			if (_done != null)
				_done(_tex, _bytes, _orientation);
		}

		void UIFailCallback()
		{
			if (_fail != null)
				_fail(_exception);
			_exception = null;
		}

		public static byte[] ResizeImage(byte[] imageData, int2 targetSize)
		{
			if (targetSize.X > 0 && targetSize.Y > 0)
			{
				if defined(Android)
					return AndroidResizeImage(imageData, targetSize.X, targetSize.Y);
				else if defined(iOS)
					return IOSResizeImage(extern<IntPtr>(imageData) "$0", targetSize.X, targetSize.Y);
				else
					return imageData;
			}
			return imageData;
		}

		[Foreign(Language.Java)]
		extern(Android) private static byte[] AndroidResizeImage(byte[] imageData, int desiredWidth, int desiredHeight)
		@{
			byte[] bitmapdata = imageData.copyArray();
			android.graphics.BitmapFactory.Options options = new android.graphics.BitmapFactory.Options();
			options.inJustDecodeBounds = true;
			android.graphics.BitmapFactory.decodeByteArray(bitmapdata, 0, bitmapdata.length, options);
			String lowerCaseType = options.outMimeType.toLowerCase();
			float width = options.outWidth;
			float height = options.outHeight;

			if (width == desiredWidth && height == desiredHeight)
				return imageData;

			options = new android.graphics.BitmapFactory.Options();
			android.graphics.Bitmap sourceBitmap = android.graphics.BitmapFactory.decodeByteArray(bitmapdata, 0, bitmapdata.length, options);
			options.inScaled = true;
			if (width < height) {
				options.inDensity = (int)height;
				options.inTargetDensity = desiredHeight;
			} else {
				options.inDensity = (int)width;
				options.inTargetDensity = desiredWidth;
			}
			float ratio = 1.0f;
			if (width > desiredWidth) {
				ratio = desiredWidth / width;
				width *= ratio;
				height *= ratio;
			}
			if (height > desiredHeight) {
				ratio = desiredHeight / height;
				width *= ratio;
				height *= ratio;
			}

			android.graphics.Bitmap resultBitmap = android.graphics.Bitmap.createScaledBitmap(
						sourceBitmap,
						(int)width,
						(int)height,
						true);

			android.graphics.Bitmap.CompressFormat fmt;
			if (lowerCaseType.contains("png"))
				fmt = android.graphics.Bitmap.CompressFormat.PNG;
			else
				fmt = android.graphics.Bitmap.CompressFormat.JPEG;
			java.io.ByteArrayOutputStream stream = new java.io.ByteArrayOutputStream();
			resultBitmap.compress(fmt, 100, stream);
			byte[] byteArray = stream.toByteArray();

			sourceBitmap.recycle();
			resultBitmap.recycle();
			bitmapdata = null;

			return new ByteArray(byteArray);
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) private static byte[] IOSResizeImage(IntPtr imageData, int desiredWidth, int desiredHeight)
		@{
			auto unoArray = (\@{byte[]})imageData;
			::uRetain(unoArray);
			::NSData* data = [[::NSData alloc]
				initWithBytesNoCopy:unoArray->Ptr()
				length:(NSUInteger)unoArray->Length()
				deallocator:^(void* bytes, NSUInteger length)
				{
					::uRelease(unoArray);
				}];

			uint8_t c;
			[data getBytes:&c length:1];
			NSString * mimeType;
			switch (c) {
				case 0x89:
					mimeType = @"image/png";
					break;
				default:
					mimeType = @"image/jpeg";
			}

			UIImage* image = [UIImage imageWithData:data];
			CGSize currentSize = [image size];
			float width = currentSize.width;
			float height = currentSize.height;
			float ratio;
			UIImage *newImage;

			if (width > desiredWidth) {
				ratio = desiredWidth / width;
				width *= ratio;
				height *= ratio;
			}
			if (height > desiredHeight) {
				ratio = desiredHeight / height;
				width *= ratio;
				height *= ratio;
			}

			UIGraphicsBeginImageContextWithOptions(CGSizeMake(width,height), NO, 1.0);
			[image drawInRect:CGRectMake(0, 0, width, height)];
			newImage = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();

			NSData *dataImage;
			if ([mimeType isEqualToString:@"image/png"])
				dataImage = UIImagePNGRepresentation(newImage);
			else
				dataImage = UIImageJPEGRepresentation(newImage, 1.0);
			return [::StrongUnoArray strongUnoArrayWithUnoArray: uArray::New(@{byte:typeof}->Array(), (int) dataImage.length, dataImage.bytes)
				getAt: ^ id (::uArray* arr, int i) { return ::uObjC::Box<uint8_t>(arr->Item<uint8_t>(i)); }
				setAt: ^ (::uArray* arr, int i, id obj) { arr->Item<uint8_t>(i) = ::uObjC::Unbox<uint8_t>(obj); }
			];
		@}
	}
}