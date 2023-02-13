using Uno.UX;
using Fuse.Scripting;

namespace Fuse.Reactive.FuseJS
{
	[UXGlobalModule]
	/**
		@scriptmodule FuseJS/Phone

		The Phone API allows you to launch your device's built-in
		phone app and make calls or send messages.

		You need to add a reference to `"Fuse.Launcher"` in your project file to use this feature.

		## Example
		```js
			var phone = require("FuseJS/Phone");
			phone.call("+47 123 45 678");
			phone.sms("+47 123 45 678", "Hi there");
		```
	*/
	public sealed class Phone : NativeModule
	{
		static readonly Phone _instance;
		public Phone()
		{
			Resource.SetGlobalKey(_instance = this, "FuseJS/Phone");
			AddMember(new NativeFunction("call", Call));
			AddMember(new NativeFunction("sms", Sms));
		}

		/**
			@scriptmethod call(number)
			@param number (String) The number to call

			Launches your device's phone app with the specified number.

			## Example
			```js
				var phone = require("FuseJS/Phone");
				phone.call("+47 123 45 678");
			```
		*/
		public static object Call(Context context, object[] args)
		{
			string phoneNumber = (string)args[0];
			Fuse.LauncherImpl.PhoneLauncher.LaunchCall(phoneNumber);
			return null;
		}

		/**
			@scriptmethod sms(number, body)
			@param number (String) The number to to send a message
			@param body (String) The message to to send

			Launches your device's messages app with the specified number.

			## Example
			```js
				var phone = require("FuseJS/Phone");
				phone.sms("+47 123 45 678", "Hi there");
			```
		*/
		public static object Sms(Context context, object[] args)
		{
			string phoneNumber = (string)args[0];
			string body = args.Length > 1 ? (string)args[1] : null;
			Fuse.LauncherImpl.PhoneLauncher.LaunchSms(phoneNumber, body);
			return null;
		}
	}
}
