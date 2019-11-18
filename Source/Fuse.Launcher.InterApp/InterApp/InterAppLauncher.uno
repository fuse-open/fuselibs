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
				try
				{
					AndroidDeviceInterop.LaunchIntent(_actionView, uri.AbsoluteUri);
				}
				catch (Exception e)
				{
					debug_log("InterApp.LaunchUri - Failed to launch uri");
				}
			}
			if defined(iOS)
			{
				iOSDeviceInterop.LaunchUriiOS(uri.AbsoluteUri);
			}
		}

		public static void LaunchApp(string uri, string appStoreUri = null)
		{
			if defined(Android)
			{
				try 
				{
					AndroidDeviceInterop.LaunchApp(_actionView, uri);
				} 
				catch (Exception e) 
				{
					debug_log("InterApp.LaunchApp - Failed to launch app");
				}
			}
			if defined(iOS)
			{
				iOSDeviceInterop.LaunchApp(uri, appStoreUri);
			}
		}
	}
}
