using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.Permissions;
using Uno.Net.Http;
using Fuse.iOS.Bindings;
using Fuse.Android.Bindings;

namespace Fuse.LauncherImpl
{
	[ForeignInclude(Language.Java, "android.content.Intent")]
	[ForeignInclude(Language.ObjC, "UIKit/UIKit.h")]
	public static class InterAppLauncher
	{
		[Foreign(Language.Java)]
		extern(Android) static string _actionView
		{
			get
			@{
				return Intent.ACTION_VIEW;
			@}
		}

		public static void LaunchUri(Uno.Net.Http.Uri uri)
		{
			if defined(Android)
			{
				Permissions.Request(Permissions.Android.INTERNET);
				try {
					AndroidDeviceInterop.LaunchIntent(_actionView, uri.AbsoluteUri);
				} catch (Exception e) {
					// ignore this error. Keeps behaviour in line with iOS
				}
			}
			if defined(iOS)
			{
				iOSDeviceInterop.LaunchUriiOS(uri.AbsoluteUri);
			}
		}
	}
}
