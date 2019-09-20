using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Text;
using Uno.Threading;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Scripting;

namespace Fuse.Controls.Native.iOS
{
	[UXGlobalModule]
	/**
		@scriptmodule FuseJS/DarkMode
		
		This module provides access to whether or not the current OS setting for Dark Mode is enabled and or changed.
		
		## Example
		
		```xml
		<App>
			<JavaScript>

				var DarkMode = require("FuseJS/DarkMode");
				var Observable = require("FuseJS/Observable");

				var isDarkMode = Observable(false);

				DarkMode.on("changed", function(val) {
					console.log("DARKMODE CHANGED: " + val);
					switch(val) {
						case 'light': isDarkMode.value = false;
							break;
						case 'dark': isDarkMode.value = true;
							break;
					}
				});

				module.exports = {
					isDarkMode
				}

			</JavaScript>
			<StackPanel Alignment="Center">
				<Text ux:Name="title" Value="Hello World!" />
			</StackPanel>
			<Rectangle ux:Name="bk" Layer="Background" Color="#FFF" />

			<WhileTrue Value="{isDarkMode}">
				<Change title.Value="Hello Dark World!" />
				<Change title.Color="#FFF" />
				<Change bk.Color="#000" />
			</WhileTrue>
			<WhileFalse Value="{isDarkMode}">
				<Change title.Value="Hello World!" />
				<Change title.Color="#000" />
				<Change bk.Color="#FFF" />
			</WhileFalse>
		</App>
		```
	*/ 
	[ForeignInclude(Language.Java,
		"java.lang.Runnable",
		"android.content.res.Configuration",
		"android.app.Activity")]
	public class DarkMode : NativeEventEmitterModule
	{
		internal static readonly DarkMode _instance;

		public DarkMode(): base(true, "changed")
		{
			if (_instance != null) return;
			Resource.SetGlobalKey(_instance = this, "FuseJS/DarkMode");

			if defined(ANDROID)
				SetupAndroidListener();
		}

		[Foreign(Language.Java)]
		extern(Android) void SetupAndroidListener() 
		@{ 
			@{checkForDarkThemeChange():Call()};

			com.fuse.Activity.SubscribeToLifecycleChange(new com.fuse.Activity.ActivityListener()
			{
				@Override public void onStop() {}
				@Override public void onStart() {}
				@Override public void onWindowFocusChanged(boolean hasFocus) {}
				@Override public void onPause() {}
				@Override public void onResume() {}
				@Override public void onDestroy() {}

				@Override public void onConfigurationChanged(android.content.res.Configuration config) 
				{ 
					@{checkForDarkThemeChange():Call()};
				}
			});
		@}
		
		[Foreign(Language.Java)]
		static extern(Android) void checkForDarkThemeChange()
		@{
			switch (com.fuse.Activity.getRootActivity().getResources().getConfiguration().uiMode & android.content.res.Configuration.UI_MODE_NIGHT_MASK) {
				case android.content.res.Configuration.UI_MODE_NIGHT_YES:
					@{changeDarkMode(string):Call("Dark")};
					break;
				case android.content.res.Configuration.UI_MODE_NIGHT_NO:
					@{changeDarkMode(string):Call("Light")};
					break; 
				case android.content.res.Configuration.UI_MODE_NIGHT_UNDEFINED:
					@{changeDarkMode(string):Call("Unspecified")};
					break; 
			}

		@}


		internal static void changeDarkMode(string modeValue) {

			if (DarkMode._instance == null) {
				new DarkMode();
			}
			
			//iOS - standardise output values
			if (modeValue == "Unspecified") {
				modeValue = "light"; //default to light
			} else if (modeValue == "Light") {
				modeValue = "light";
			} else if (modeValue == "Dark") {
				modeValue = "dark";
			}

			DarkMode._instance.receivedDarkModeChangedEvent(modeValue);
		}

		public void receivedDarkModeChangedEvent(string modeValue) {
			Emit("changed", modeValue);
		}

	}
}
