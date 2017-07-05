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
	[ForeignInclude(Language.Java, "android.content.Intent", "android.net.Uri", "android.app.Activity")]
	[ForeignInclude(Language.ObjC, "UIKit/UIKit.h")]
	public static class EmailLauncher
	{
		[Foreign(Language.Java)]
		extern(Android) static string _actionSendTo
		{
			get
			@{
				return Intent.ACTION_SENDTO;
			@}
		}

		public static void LaunchEmail(string to, string carbonCopy, string blindCarbonCopy, string subject, string message)
		{
			if (to == null)
				throw new ArgumentNullException(nameof(to));
			var builder = new StringBuilder();
			builder.Append("mailto:");
			builder.Append(to);
			builder.Append("?");
			if(!String.IsNullOrEmpty(carbonCopy))
			{
				builder.Append("cc=");
				builder.Append(carbonCopy);
			}

			if(!String.IsNullOrEmpty(blindCarbonCopy))
			{
				builder.Append("&");
				builder.Append("bcc=");
				builder.Append(blindCarbonCopy);
			}

			if(!String.IsNullOrEmpty(subject))
			{
				builder.Append("&");
				builder.Append("subject=");
				builder.Append(Uri.Encode(subject));
			}

			if(!String.IsNullOrEmpty(message))
			{
				builder.Append("&");
				builder.Append("body=");
				builder.Append(Uri.Encode(message));
			}
			//mailto:foo@example.com?cc=bar@example.com&subject=Greetings%20from%20Cupertino!&body=Wish%20you%20were%20here!

			if defined(Android)
			{
				Permissions.Request(Permissions.Android.INTERNET);
				AndroidDeviceInterop.LaunchIntent(_actionSendTo, builder.ToString());
			}
			if defined(iOS)
			{
				iOSDeviceInterop.LaunchUriiOS(builder.ToString());
			}
		}
	}
}
