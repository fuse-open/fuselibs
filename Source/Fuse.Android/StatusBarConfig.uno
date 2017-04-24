using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Platform;

namespace Fuse.Android
{
	[ForeignInclude(Language.Java,
		"android.graphics.Color",
		"android.os.Build",
		"android.view.View",
		"android.view.ViewTreeObserver",
		"android.view.Window",
		"android.view.WindowManager.LayoutParams")]
	extern(Android) internal static class StatusBarHelper
	{
		[Foreign(Language.Java)]
		public static int GetStatusBarColor()
		@{
			Window window = com.fuse.Activity.getRootActivity().getWindow();
			if (Build.VERSION.SDK_INT >= 21)
				return window.getStatusBarColor();
			else
				return Color.BLACK;
		@}

		[Foreign(Language.Java)]
		public static bool SetStatusBarColor(int color)
		@{
			Window window = com.fuse.Activity.getRootActivity().getWindow();
			if (Build.VERSION.SDK_INT >= 21)
			{
				window.addFlags(LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
				window.setStatusBarColor(color);
				return true;
			}
			else
				return false;
		@}

		[Foreign(Language.Java)]
		public static void InstallGlobalListener()
		@{
			Window window = com.fuse.Activity.getRootActivity().getWindow();
			window.getDecorView().getViewTreeObserver().addOnGlobalFocusChangeListener(
				new ViewTreeObserver.OnGlobalFocusChangeListener() {
					boolean _focusWasEditText;
					public void onGlobalFocusChanged(View oldFocus, View newFocus) {
						if (_focusWasEditText)
							@{StatusBarConfig.UpdateStatusBar():Call()};

						_focusWasEditText = newFocus instanceof android.widget.EditText;
					}
				}
			);
		@}
	}

	/**
		Configures the appearance of the status bar on *Android*.
		
		To configure the status bar on *iOS*, see [iOS.StatusBarConfig](api:fuse/ios/statusbarconfig).
		
		> *Note*: This has no effect on Android versions prior to 5.0 (API level 21).
		
		## Example
		
		To configure the status bar on Android, place an `Android.StatusBarConfig` somewhere in your UX tree.
		
			<App>
				<Android.StatusBarConfig Color="#0003" IsVisible="True" />
				
				<!-- The rest of our app -->
			</App>
		
		However, we usually want to configure the status bar for iOS as well.
		We'll add an additional [iOS.StatusBarConfig](api:fuse/ios/statusbarconfig).
		
			<Android.StatusBarConfig Color="#0003" IsVisible="True" />
			<iOS.StatusBarConfig Style="Light" Animation="Slide" IsVisible="True" />
	*/
	public class StatusBarConfig: Behavior
	{
		extern(Android) static StatusBarConfig()
		{
			_isVisible = SystemUI.IsTopFrameVisible;
			StatusBarHelper.InstallGlobalListener();
		}

		/** The color of the status bar. */
		public float4 Color
		{
			get
			{
				if defined(Android)
					return Uno.Color.FromArgb((uint)StatusBarHelper.GetStatusBarColor());
				else
					return float4(0, 0, 0, 1);
			}
			set
			{
				if defined(Android)
				{
					if (!SetStatusBarColor(value))
						Fuse.Diagnostics.UserWarning("StatusBarConfig.Color is only supported on Android API-level 21 and higher", this);
				}
			}
		}

		static bool _isVisible = true;
		/** Whether or not the status bar should be visible. */
		public bool IsVisible
		{
			get { return _isVisible; }
			set
			{
				_isVisible = value;
				if defined(Android)
					UpdateStatusBar();
			}
		}

		extern(Android) internal static bool SetStatusBarColor(float4 color)
		{
			return StatusBarHelper.SetStatusBarColor((int)Uno.Color.ToArgb(color));
		}

		extern(Android) internal static void UpdateStatusBar()
		{
			SystemUI.IsTopFrameVisible = _isVisible;
		}
	}

}
