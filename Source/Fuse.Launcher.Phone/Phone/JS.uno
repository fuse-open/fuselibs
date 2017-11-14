using Uno.UX;
using Fuse.Scripting;

namespace Fuse.Reactive.FuseJS
{
	[UXGlobalModule]
	/**
		@scriptmodule FuseJS/Phone

		The Phone API allows you to launch your device's built-in
		phone app and make calls.

		You need to add a reference to `"Fuse.Launcher"` in your project file to use this feature.

		## Example

			var phone = require("FuseJS/Phone");
			phone.call("+47 123 45 678");
	*/
	public sealed class Phone : NativeModule
	{
		static readonly Phone _instance;
		public Phone()
		{
			Resource.SetGlobalKey(_instance = this, "FuseJS/Phone");
			AddMember(new NativeFunction("call", Call));
		}

		/**
			@scriptmethod call(number)
			@param number (String) The number to call

			Launches your device's phone app with the specified number.

			## Example

				var phone = require("FuseJS/Phone");
				phone.call("+47 123 45 678");

		*/
		public static object Call(Scripting.Context context, object[] args)
		{
			string callString = (string)args[0];
			Fuse.LauncherImpl.PhoneLauncher.LaunchCall(callString);
			return null;
		}
	}
}
