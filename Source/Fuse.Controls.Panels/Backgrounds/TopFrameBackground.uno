using Uno;
using Uno.UX;

using Fuse.Elements;
using Fuse.Platform;
using Fuse.Reactive;

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
		WindowCaps _caps;
		
		protected override void OnRooted()
		{
			base.OnRooted();
			_caps = WindowCaps.AttachFrom(this);
			_caps.AddPropertyListener(this);
		}

		protected override void OnUnrooted()
		{
			base.OnUnrooted();
			_caps.RemovePropertyListener(this);
			_caps.Detach();
			_caps = null;
		}

		public override void OnPropertyChanged(PropertyObject sender, Selector name)
		{
			base.OnPropertyChanged(sender, name);
			if (sender == _caps && name == WindowCaps.NameSafeMargins)
				InvalidateLayout();
		}

		protected override float2 GetContentSize(LayoutParams lp)
		{
			var v = float4(0);
			if (!Marshal.TryToType<float4>(_caps[WindowCaps.NameSafeMargins], out v))
				return float2(0);
			return float2(0,v.Y);
		}
	}

}
