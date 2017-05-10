
using Uno;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls.Native.Android
{
	extern(Android) public abstract class LeafView : View, ILeafView
	{
		protected LeafView(Java.Object handle) : base(handle, true) {}

		protected LeafView(Java.Object handle, bool handlesInput) : base(handle, true, handlesInput) {}
	}
}