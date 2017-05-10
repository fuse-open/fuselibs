using Uno;
using Uno.Compiler.ExportTargetInterop;

using Fuse.Drawing;

namespace Fuse.Controls.Native.iOS
{
	extern(iOS) public abstract class View : ViewHandle, IView
	{
		public ObjC.Object Handle { get { return _handle; } }

		readonly ObjC.Object _handle;

		protected View(ObjC.Object handle) : this(handle, false) {}

		protected View(ObjC.Object handle, bool isLeafView) : base(handle, isLeafView)
		{
			_handle = handle;
		}
	}
}