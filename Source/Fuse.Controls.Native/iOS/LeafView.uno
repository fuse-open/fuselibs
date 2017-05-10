using Uno;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls.Native.iOS
{
	extern(iOS) public abstract class LeafView : View, ILeafView
	{
		protected LeafView(ObjC.Object handle) : base(handle, true) { }
	}
}