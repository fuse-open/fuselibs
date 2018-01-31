using Uno;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls
{
	[Obsolete]
	/** @Deprecated */
	public sealed class RightFrameBackground : Control
	{
		public RightFrameBackground()
		{
			Fuse.Diagnostics.Deprecated("Fuse.Controls.RightFrameBackground has been deprecated, as it's no longer needed, and does nothing. Please remove the usage", this);
		}

		protected override float2 GetContentSize(LayoutParams lp)
		{
			return float2(0, 0);
		}
	}
}
