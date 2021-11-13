using Uno;
using Uno.UX;
using Uno.Collections;
using Fuse.Scripting;

namespace Fuse.Reactive.FuseJS
{
	[UXGlobalModule]
	/**
		@scriptmodule FuseJS/InAppBrowser

		The InAppBrowser API allows you to launch In App Browser

		You need to add a reference to `"Fuse.Launcher"` in your project file to use this feature.

		## Example

		```javascript
			var inAppBrowser = require("FuseJS/InAppBrowser");
			inAppBrowser.openUrl("https://fuseopen.com");
		```
	*/
	public class InAppBrowserModule : NativeModule
	{
		static InAppBrowserModule _instance;

		public InAppBrowserModule()
		{
			if (_instance != null)
				return;

			_instance = this;
			Resource.SetGlobalKey(_instance, "FuseJS/InAppBrowser");

			AddMember(new NativeFunction("openUrl", (NativeCallback)OpenUrl));
		}

		object[] OpenUrl(Context c, object[] args)
		{
			var url = args.ValueOrDefault<string>(0,"");
			if (url == "")
				throw new Exception("You need to supply a valid url");

			Fuse.LauncherImpl.InAppBrowserLauncher.LaunchInAppBrowser(url);
			return null;
		}
	}

}