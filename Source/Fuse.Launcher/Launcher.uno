using Uno;
using Uno.Text;
using Uno.IO;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Android.Permissions;
using Uno.Net.Http;
using Fuse.LauncherImpl;

namespace Fuse
{
	public static class Launcher
	{
		public static void LaunchUri(Uri uri)
		{
			InterAppLauncher.LaunchUri(uri);
		}

		public static void LaunchCall(string phoneNumber)
		{
			PhoneLauncher.LaunchCall(phoneNumber);
		}

		public static void LaunchSms(string phoneNumber, string body)
		{
			PhoneLauncher.LaunchSms(phoneNumber, body);
		}

		public static void LaunchMaps(double latitude, double longitude)
		{
			MapsLauncher.LaunchMaps(latitude, longitude);
		}

		public static void LaunchMaps(string query)
		{
			MapsLauncher.LaunchMaps(query);
		}

		public static void LaunchMaps(double latitude, double longitude, string query)
		{
			MapsLauncher.LaunchMaps(latitude, longitude, query);
		}

		public static void LaunchEmail(string to, string carbonCopy, string blindCarbonCopy, string subject, string message)
		{
			EmailLauncher.LaunchEmail(to, carbonCopy, blindCarbonCopy, subject, message);
		}

		public static void LaunchInAppBrowser(string url)
		{
			InAppBrowserLauncher.LaunchInAppBrowser(url);
		}
	}
}
