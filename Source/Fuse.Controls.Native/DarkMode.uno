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
	public class DarkMode : NativeEventEmitterModule
	{
		public static readonly DarkMode _instance;

		public DarkMode(): base(true, "changed")
		{
			if (_instance != null) return;
			Resource.SetGlobalKey(_instance = this, "FuseJS/DarkMode");
		}

		/* 
			Example call for when implementing Android version:
			@{Fuse.Controls.Native.iOS.DarkMode.changeDarkMode(string):Call(@"Dark")};
		*/
		public static void changeDarkMode(string modeValue) {

			if (DarkMode._instance == null) {
				new DarkMode();
			}
			
			//Android(ToDo) - standardise output values
			
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
