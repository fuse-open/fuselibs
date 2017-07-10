using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls.Native
{
	[ForeignInclude(Language.Java,
		"android.graphics.Color",
		"android.os.Build",
		"android.view.View",
		"android.view.WindowManager",
		"android.view.Window",
		"android.view.WindowManager.LayoutParams")]
	//Requires android SDK version 16 or newer(Jelly Bean)
	extern(Android) internal static class SystemUiVisibility
	{
		[Flags]
		public enum Flag 
		{
			None = 0,
			LowProfile = 1, 
			HideNavigation = 2, 
			Fullscreen = 4, 
			LayoutStable = 256, 
			LayoutHideNavigation = 512, 
			LayoutFullscreen = 1024, 
			Immersive = 2048, 
			ImmersiveSticky = 4096
		}

		public delegate void VisibilityChangedHandler(Flag newFlag);

		public static event VisibilityChangedHandler VisibilityChanged;

		static SystemUiVisibility()
		{
			JavaInit();
		}

		public static Flag Flags {
			get 
			{
				return getVisibilityFlags();
			}
			set 
			{
				setVisibilityFlags(value);
			}
		}

		[Foreign(Language.Java)]
		private static void JavaInit()
		@{
			com.fuse.Activity.getRootActivity().runOnUiThread(new Runnable() {
				@Override
				public void run() {
					View decorView = com.fuse.Activity.getRootActivity().getWindow().getDecorView();
					decorView.setOnSystemUiVisibilityChangeListener(new View.OnSystemUiVisibilityChangeListener() {
						public void onSystemUiVisibilityChange(int visibility) {
							@{callEvent(int):Call(visibility)};
						}
					});
				}
			});
		@}

		private static void callEvent(int flags) 
		{
			if(VisibilityChanged != null)
				VisibilityChanged((Flag)flags);
		}

		[Foreign(Language.Java)]
		private static Flag getVisibilityFlags()
		@{
			View decorView = com.fuse.Activity.getRootActivity().getWindow().getDecorView();
			return decorView.getSystemUiVisibility();
		@}
		[Foreign(Language.Java)]
		public static void setVisibilityFlags(Flag flags)
		@{
			com.fuse.Activity.getRootActivity().runOnUiThread(new Runnable() {
				@Override
				public void run() {
						View decorView = com.fuse.Activity.getRootActivity().getWindow().getDecorView();
						decorView.setSystemUiVisibility(flags);
				}
			});
		@}
	}
}
