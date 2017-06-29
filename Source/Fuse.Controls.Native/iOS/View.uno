using Uno;
using Uno.Compiler;
using Uno.Compiler.ExportTargetInterop;

using Fuse.Drawing;

namespace Fuse.Controls.Native.iOS
{
	extern(iOS) public abstract class View : ViewHandle, IView
	{
		public ObjC.Object Handle { get { return _handle; } }

		readonly ObjC.Object _handle;

		protected View(ObjC.Object handle, ViewHandle.InputMode inputmode = ViewHandle.InputMode.Automatic) : this(handle, false, inputmode) {}

		protected View(ObjC.Object handle, bool isLeafView, ViewHandle.InputMode inputmode = ViewHandle.InputMode.Automatic) : base(handle, isLeafView, inputmode)
		{
			_handle = handle;
		}

		protected void DispatchTouchesBegan(Visual origin, ObjC.Object touches, [CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0)
		{
			if (ErrorCheck(touches, filePath, lineNumber))
				InputDispatch.OnTouchesBegan(origin, touches);
		}

		protected void DispatchTouchesMoved(Visual origin, ObjC.Object touches, [CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0)
		{
			if (ErrorCheck(touches, filePath, lineNumber))
				InputDispatch.OnTouchesMoved(origin, touches);
		}

		protected void DispatchTouchesEnded(Visual origin, ObjC.Object touches, [CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0)
		{
			if (ErrorCheck(touches, filePath, lineNumber))
				InputDispatch.OnTouchesEnded(origin, touches);
		}

		protected void DispatchTouchesCancelled(Visual origin, ObjC.Object touches, [CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0)
		{
			if (ErrorCheck(touches, filePath, lineNumber))
				InputDispatch.OnTouchesCancelled(origin, touches);
		}

		static bool ErrorCheck(ObjC.Object touches, string filePath, int lineNumber)
		{
			if (IsNsArrayOfUITouch(touches))
				return true;
			Fuse.Diagnostics.UserError(
				"Could not dispatch inputevent, expected " + ExpectedType() + ", but got: " + GetType(touches),
				touches,
				filePath,
				lineNumber,
				"touches");
			return false;
		}

		[Foreign(Language.ObjC)]
		static bool IsNsArrayOfUITouch(ObjC.Object touches)
		@{
			return [touches isKindOfClass:[NSArray<UITouch*> class]];
		@}

		[Foreign(Language.ObjC)]
		static string ExpectedType()
		@{
			return NSStringFromClass([NSArray<UITouch*> class]);
		@}

		[Foreign(Language.ObjC)]
		static string GetType(ObjC.Object obj)
		@{
			return NSStringFromClass([obj class]);
		@}
	}
}