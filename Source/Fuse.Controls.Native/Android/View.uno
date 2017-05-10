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

		protected View(Java.Object handle, bool isLeafView) : this(handle, isLeafView, false) {}

		protected View(Java.Object handle, bool isLeafView, bool handlesInput) : base(handle, isLeafView, handlesInput)
		{
			_handle = handle;
		}
	}
}