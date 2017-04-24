using Uno;
using Uno.Graphics;
using OpenGL;
using Fuse.Elements;
using Fuse.Controls.Graphics;
using Fuse.Resources;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Android
{

	extern (Android) internal class Bitmap : IDisposable
	{
		public Java.Object Handle
		{
			get { return _handle; }
		}

		readonly Java.Object _handle;

		public Bitmap(Java.Object handle)
		{
			_handle = handle;
		}

		public void EraseColor(float4 color)
		{
			EraseColor(Handle, (int)Color.ToArgb(color));
		}

		public static Bitmap CreateBitmapARGB8888(int width, int height)
		{
			return new Bitmap(CreateBitmapARGB8888Impl(width, height));
		}

		public void Recycle()
		{
			Recycle(Handle);
		}

		bool _isDisposed = false;
		public void Dispose()
		{
			if (!_isDisposed)
			{
				Recycle();
				_isDisposed = true;
			}
		}

		[Foreign(Language.Java)]
		static void Recycle(Java.Object handle)
		@{
			((android.graphics.Bitmap)handle).recycle();
		@}

		[Foreign(Language.Java)]
		static Java.Object CreateBitmapARGB8888Impl(int width, int height)
		@{
			return android.graphics.Bitmap.createBitmap(width, height, android.graphics.Bitmap.Config.ARGB_8888);
		@}

		[Foreign(Language.Java)]
		static void EraseColor(Java.Object handle, int color)
		@{
			((android.graphics.Bitmap)handle).eraseColor(color);
		@}

	}

}