using Uno;
using Uno.Compiler.ExportTargetInterop;

using Fuse.Drawing;

namespace Fuse.Controls.Native.Android
{
	extern(Android) public abstract class View : ViewHandle, IView
	{
		public Java.Object Handle { get { return _handle; } }

		readonly Java.Object _handle;

		protected View(Java.Object handle) : this(handle, false) {}

		protected View(Java.Object handle, bool isLeafView) : base (handle, isLeafView)
		{
			_handle = handle;
		}
	}
}