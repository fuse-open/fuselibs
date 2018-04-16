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
	public static class MapsLauncher
	{
		[Foreign(Language.Java)]
		extern(Android) static string _actionView
		{
			get
			@{
				return Intent.ACTION_VIEW;
			@}
		}

		public static void LaunchMaps(double latitude, double longitude)
		{
			if defined(Android || iOS)
			{
				var latlon = latitude.ToString() + "," + longitude.ToString();

				if defined(Android)
					LaunchMapsAndroid("geo:" + latlon + "?q=" + latlon);
				else if defined(iOS)
					iOSDeviceInterop.LaunchUriiOS("http://maps.apple.com/maps?q=" + latlon + "&ll=" + latlon);
			}
		}

		public static void LaunchMaps(string query)
		{
			query = Uri.EscapeDataString(query);
			if defined(Android)
				LaunchMapsAndroid("geo:0,0?q=" + query);
			else if defined(iOS)
				iOSDeviceInterop.LaunchUriiOS("http://maps.apple.com/maps?q=" + query);
		}

		public static void LaunchMaps(double latitude, double longitude, string query)
		{
			if defined(Android || iOS)
			{
				var latlon = latitude.ToString() + "," + longitude.ToString();
				query = Uri.EscapeDataString(query);

				if defined(Android)
					LaunchMapsAndroid("geo:" + latlon + "?q=" + query);
				if defined(iOS)
					iOSDeviceInterop.LaunchUriiOS("http://maps.apple.com/maps?q=" + query + "&sll=" + latlon);
			}
		}

		static extern(android) void LaunchMapsAndroid(string uri)
		{
			try
			{
				AndroidDeviceInterop.LaunchIntent(_actionView, uri, "com.google.android.apps.maps", "com.google.android.maps.MapsActivity");
			}
			catch (Exception e)
			{
				// ignore this error. Keeps behaviour in line with iOS
			}
		}
	}
}
