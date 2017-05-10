using Uno;
using Uno.Text;
using Uno.IO;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Uno.Permissions;
using Uno.Net.Http;
using Fuse.iOS.Bindings;
using Fuse.Android.Bindings;

namespace Fuse.LauncherImpl
{
	public static class PhoneLauncher
	{
		public static void LaunchCall(string callString)
		{
			if defined(Android || iOS)
			{
				var uri = PhoneUriHelper.PhoneNumberToUri(callString);

				if defined(Android)
				{
					var call = new AndroidCall(uri);
					call.Begin();
				}
				if defined(iOS)
				{
					iOSDeviceInterop.LaunchUriiOS(uri);
				}
			}
		}
	}

	[ForeignInclude(Language.Java, "android.content.Intent", "android.net.Uri", "android.app.Activity")]
	extern(Android) class AndroidCall
	{
		string _uri;

		[Foreign(Language.Java)]
		extern(Android) static string _actionCall
		{
			get
			@{
				return Intent.ACTION_CALL;
			@}
		}

		public AndroidCall(string uri)
		{
			_uri = uri;
		}

		public void Begin()
		{
			Permissions.Request(Permissions.Android.CALL_PHONE).Then(OnPermitted);
		}

		extern(Android) void OnPermitted(PlatformPermission permission)
		{
			AndroidDeviceInterop.LaunchIntent(_actionCall, _uri);
		}
	}
}
