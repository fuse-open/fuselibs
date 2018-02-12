using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.Platform2;
using Fuse.Platform;

namespace Fuse.Platform
{
	enum SystemUIResizeReason
	{
		WillShow,
		WillChangeFrame,
		WillHide,
	}

	enum SysUIState // was SystemUI.UIState
	{
		Normal = 0,
		StatusBarHidden = 1,
		Fullscreen = 2,
	}

	static extern(!iOS && !Android) class SystemUI
	{
	}
}
