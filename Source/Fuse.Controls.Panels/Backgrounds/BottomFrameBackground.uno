using Uno;
using Fuse.Elements;
using Fuse.Platform;
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

		protected override void OnRooted()
		{
			base.OnRooted();

			if defined(iOS || Android)
			{
				_height = SystemUI.BottomFrame.Size.Y;
				SystemUI.BottomFrameWillResize += OnFrameResized;
			}
		}
		protected override void OnUnrooted()
		{
			base.OnUnrooted();
			if defined(iOS || Android)
				SystemUI.BottomFrameWillResize -= OnFrameResized;
		}

		float _height;

		extern(ANDROID || IOS)
		private void OnFrameResized(object sender, SystemUIWillResizeEventArgs args)
		{
			var newHeight = args.EndFrame.Size.Y;

			// Temp hack because backends report SystemUI.BottomFrame differentl
			// Joao is on fixing that
			if defined(iOS)
			{
				newHeight = Rect.Intersect(SystemUI.Frame, SystemUI.BottomFrame).Size.Y;
			}


			if (IncludesKeyboard || newHeight < KeyboardVisibleThreshold)
			{
				_height = newHeight;
				InvalidateLayout();
			}
		}

		protected override float2 GetContentSize(LayoutParams lp)
		{
			if defined(iOS || Android)
			{
				return float2(lp.HasX ? lp.X : 0, _height / AppBase.Current.PixelsPerPoint);
			}

			return float2(0,0);
		}
	}
}
