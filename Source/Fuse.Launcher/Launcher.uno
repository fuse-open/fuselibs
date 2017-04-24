using Uno;
using Uno.Text;
using Uno.IO;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Uno.Permissions;
using Uno.Net.Http;
using Fuse.LauncherImpl;

namespace Fuse
{
	public static class Launcher
	{
		public static void LaunchUri(Uno.Net.Http.Uri uri)
		{
			InterAppLauncher.LaunchUri(uri);
		}

		public static void LaunchCall(string callString)
		{
			PhoneLauncher.LaunchCall(callString);
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
	}
}
