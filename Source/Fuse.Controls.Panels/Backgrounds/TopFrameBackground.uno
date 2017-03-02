using Uno;

using Fuse.Elements;
using Fuse.Platform;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls
{
	/** Compensates for space taken up by the status bar.

		`StatusBarBackground` will always have the same size as the status bar across all platforms and devices.

		## Example

		The following example demonstrates how a `StatusBarBackground` can be docked inside a `DockPanel` to ensure the rest of the app's content (inside by the `Panel`) will be placed below the status bar.

			<DockPanel>
				<StatusBarBackground Dock="Top"/>
				<Panel>
					<Text>This text will be below the status bar</Text>
				</Panel>
			</DockPanel>

		See also @BottomBarBackground.
	*/
	public class StatusBarBackground : TopFrameBackground { }

	public class TopFrameBackground: Control
	{
		protected override void OnRooted()
		{
			base.OnRooted();
			if defined(iOS || Android)
				SystemUI.TopFrameWillResize += OnFrameResized;
		}

		protected override void OnUnrooted()
		{
			base.OnUnrooted();
			if defined(iOS || Android)
				SystemUI.TopFrameWillResize -= OnFrameResized;
		}

		extern(ANDROID || IOS)
		private void OnFrameResized(object sender, SystemUIWillResizeEventArgs args)
		{
			InvalidateLayout();
		}

		protected override float2 GetContentSize(LayoutParams lp)
		{
			if defined(iOS) {
				// on iOS, we always treat the bar as though it's 40 points
				var height = 40 / AppBase.Current.PixelsPerPoint;
				var x = SystemUI.TopFrame.Size.X / AppBase.Current.PixelsPerPoint;
				return float2(x, height);
			}
			else if defined(Android)
			{
				var x = SystemUI.TopFrame.Size / AppBase.Current.PixelsPerPoint;
				return x;
			}
			return float2(0,0);
		}
	}

}
