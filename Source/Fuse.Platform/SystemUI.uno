using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.Platform2;
using Fuse.Platform;

namespace Fuse.Platform
{
	public enum SystemUIID
	{
		TopFrame,
		BottomFrame,
	}

	public enum SystemUIResizeReason
	{
		WillShow,
		WillChangeFrame,
		WillHide,
	}

	internal enum SysUIState // was SystemUI.UIState
	{
		Normal = 0,
		StatusBarHidden = 1,
		Fullscreen = 2,
	}

	public class SystemUIWillResizeEventArgs : EventArgs
	{
		public SystemUIID ID { get; private set; }
		public SystemUIResizeReason ResizeReason { get; private set; }
		public Rect StartFrame { get; private set; }
		public Rect EndFrame { get; private set; }
		public bool IsAnimated { get; private set; }
		public double AnimationDuration { get; private set; }
		public int AnimationCurve { get; private set; }


		public SystemUIWillResizeEventArgs(
			   SystemUIID id,
			   SystemUIResizeReason resizeReason,
			   Rect endFrame, Rect startFrame = new Rect(),
			   double animationDuration = 0, int animationCurve = 0)
		{
			ID = id;
			ResizeReason = resizeReason;
			StartFrame = startFrame;
			EndFrame = endFrame;

			if (animationDuration != 0)
			{
				IsAnimated = true;
				AnimationDuration = animationDuration;
				AnimationCurve = animationCurve;
			}
		}
	}
}
