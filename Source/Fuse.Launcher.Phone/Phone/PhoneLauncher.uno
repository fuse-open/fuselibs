using Uno.Compiler.ExportTargetInterop;
using Fuse.Android.Permissions;
using Fuse.Android.Bindings;
using Fuse.iOS.Bindings;

namespace Fuse.LauncherImpl
{
	public static class PhoneLauncher
	{
		public static void LaunchCall(string phoneNumber)
		{
			if defined(Android || iOS)
			{
				var uri = PhoneUriHelper.PhoneNumberToTelUri(phoneNumber);

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

		public static void LaunchSms(string phoneNumber, string body)
		{
			if defined(Android || iOS)
			{
				var uri = PhoneUriHelper.PhoneNumberToSmsUri(phoneNumber, body);

				if defined(Android)
				{
					var sms = new AndroidSms(uri);
					sms.Launch();
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
		extern(Android) static string _action
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

		void OnPermitted(PlatformPermission permission)
		{
			AndroidDeviceInterop.LaunchIntent(_action, _uri);
		}
	}

	[ForeignInclude(Language.Java, "android.content.Intent", "android.net.Uri", "android.app.Activity")]
	extern(Android) class AndroidSms
	{
		string _uri;

		[Foreign(Language.Java)]
		extern(Android) static string _action
		{
			get
			@{
				return Intent.ACTION_VIEW;
			@}
		}

		public AndroidSms(string uri)
		{
			_uri = uri;
		}

		public void Launch()
		{
			AndroidDeviceInterop.LaunchIntent(_action, _uri);
		}
	}
}
