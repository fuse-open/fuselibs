using Uno;
using Uno.Graphics;
using OpenGL;
using Fuse.Elements;
using Fuse.Controls.Graphics;
using Fuse.Resources;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Android
{

	extern (Android) internal class Canvas
	{
		public Java.Object Handle
		{
			get { return _handle; }
		}

		readonly Java.Object _handle;

		public Canvas(Java.Object handle)
		{
			_handle = handle;
		}

		public Canvas(Bitmap bitmap) : this(Create(bitmap.Handle)) { }

		public void Translate(float dx, float dy)
		{
			Translate(Handle, dx, dy);
		}

		[Foreign(Language.Java)]
		static void Translate(Java.Object handle, float dx, float dy)
		@{
			((android.graphics.Canvas)handle).translate(dx, dy);
		@}

		[Foreign(Language.Java)]
		static Java.Object Create(Java.Object bitmapHandle)
		@{
			return new android.graphics.Canvas(((android.graphics.Bitmap)bitmapHandle));
		@}

	}
}