using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls.Native.iOS
{
	extern(iOS)
	internal static class ObjectExtensions
	{
		[Foreign(Language.ObjC)]
		public static bool IsUIControl(this ObjC.Object obj)
		@{
			return [obj isKindOfClass:[UIControl class]];
		@}

		[Foreign(Language.ObjC)]
		public static bool IsUIEvent(this ObjC.Object obj)
		@{
			return [obj isKindOfClass:[UIEvent class]];
		@}
	}
}