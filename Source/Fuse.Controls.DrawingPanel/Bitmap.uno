using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.UX;
using Uno.Threading;
using Uno.Collections;
using Fuse.Resources.Exif;
using Fuse.Input;
using Fuse.Scripting;
using Fuse.Controls.Internal;
using Fuse.Controls.Native.iOS;
using Fuse.Controls.Native.Android;

namespace Fuse.Controls
{
	extern(ANDROID) internal class Bitmap : IDisposable
	{
		public Java.Object Handle { get { return _handle; } }

		public int2 PixelSize { get { return int2(GetWidth(_handle), GetHeight(_handle)); } }

		Java.Object _handle;

		Bitmap(byte[] bytes)
		{
			_handle = Load(Fuse.Android.Bindings.AndroidDeviceInterop.MakeBufferInputStream(bytes));
		}

		public Bitmap(Java.Object bitmap)
		{
			_handle = bitmap;
		}

		public void Dispose()
		{
			if (_handle != null)
			{
				Release(_handle);
				_handle = null;
			}
		}

		public static Bitmap FromJpegBytes(byte[] bytes)
		{
			return new Bitmap(bytes);
		}

		class SavePromise : Promise<string>
		{
			public void OnRejected(string msg) { Reject(new Exception(msg)); }
		}

		public Future<string> SaveJpeg()
		{
			var sp = new SavePromise();
			SaveJpeg(_handle, sp.Resolve, sp.OnRejected);
			return sp;
		}

		[Foreign(Language.Java)]
		static void SaveJpeg(
			Java.Object handle,
			Action<string> onResolve,
			Action<string> onReject)
		@{
			String filePath;
			try {
				filePath = com.fuse.camera.ImageStorageTools.createFilePath("jpeg", true);
				java.io.FileOutputStream file = new java.io.FileOutputStream(filePath);
				((android.graphics.Bitmap)handle).compress(
					android.graphics.Bitmap.CompressFormat.JPEG,
					100,
					file);
				file.close();
				onResolve.run(filePath);
			} catch(Exception e) {
				onReject.run(e.getMessage());
			}
		@}

		[Foreign(Language.Java)]
		static int GetWidth(Java.Object handle)
		@{
			return ((android.graphics.Bitmap)handle).getWidth();
		@}

		[Foreign(Language.Java)]
		static int GetHeight(Java.Object handle)
		@{
			return ((android.graphics.Bitmap)handle).getHeight();
		@}

		[Foreign(Language.Java)]
		static void Release(Java.Object handle)
		@{
			((android.graphics.Bitmap)handle).recycle();
		@}

		[Foreign(Language.Java)]
		static Java.Object Load(Java.Object buf)
		@{
			return android.graphics.BitmapFactory.decodeStream((java.io.InputStream)buf);
		@}
	}
}