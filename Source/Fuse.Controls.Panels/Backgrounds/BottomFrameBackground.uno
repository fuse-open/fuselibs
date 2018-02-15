using Uno;
using Uno.UX;

using Fuse.Elements;
using Fuse.Platform;
using Fuse.Reactive;

using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls
{
	/** Compensates for space taken up by the keyboard and other OS-specific elements at the bottom of the screen.

		Similar to the @StatusBarBackground in that it takes on the same size as certain OS-specific elements.
		The `BottomBarBackground` will take on the same size as the keyboard (whenever it is visible).
		Certain Android devices have their home button on the screen instead of as a physical button.
		The `BottomBarBackground` will also take this into account when sizing itself.

		## Example

		The following example demonstrates how a `BottomBarBackground` can be docked inside a `DockPanel` to ensure the rest of the app's content (inside by the `Panel`) will be placed above the bottom bar.

			<DockPanel>
				<BottomBarBackground Dock="Bottom" />
				<Panel>
					<Text>This text will be above the bottom bar</Text>
				</Panel>
			</DockPanel>

		You also have the option to not take the size of the keyboard into account:

			<BottomBarBackground IncludesKeyboard="false" />
			
	*/
	public class BottomBarBackground : BottomFrameBackground { }


	public class BottomFrameBackground : Control
	{
		bool _includesKeyboard = true;
		/** Controls whether space taken up by the on-screen keyboard should be taken into account or not.
			@default true
		*/
		public bool IncludesKeyboard
		{
			get { return _includesKeyboard; }
			set
			{
				if (_includesKeyboard != value)
				{
					_includesKeyboard = value;
					InvalidateLayout();
				}
			}
		}

		float _keyboardVisibleThreshold = 150;
		public float KeyboardVisibleThreshold
		{
			get { return _keyboardVisibleThreshold; }
			set
			{
				if (_keyboardVisibleThreshold != value)
				{
					_keyboardVisibleThreshold = value;
					InvalidateLayout();
				}
			}
		}

		WindowCaps _caps;
		protected override void OnRooted()
		{
			base.OnRooted();
			_caps = WindowCaps.AttachFrom(this);
			_caps.AddPropertyListener(this);
		}

		protected override void OnUnrooted()
		{
			_caps.RemovePropertyListener(this);
			_caps.Detach();
			_caps = null;
			base.OnUnrooted();
		}

		float _height;

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
				
			if (IncludesKeyboard || v.W < KeyboardVisibleThreshold)
				_height = v.W;

			return float2(0,_height);
		}
	}
}
