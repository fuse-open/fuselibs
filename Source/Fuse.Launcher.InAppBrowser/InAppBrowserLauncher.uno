using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.LauncherImpl
{
	public static class InAppBrowserLauncher
	{
		public static void LaunchInAppBrowser(string url)
		{
			if defined(iOS)
				InAppBrowseriOSImpl.OpenUrl(url);
			if defined(Android)
				InAppBrowserAndroidImpl.OpenUrl(url);
		}

	}

	extern(iOS) class InAppBrowseriOSImpl
	{

		public static void OpenUrl(string url)
		{
			Safari.PresentSafari(url);
		}

	}

	extern(Android) class InAppBrowserAndroidImpl
	{

		public static void OpenUrl(string url)
		{
			Chrome.PresentChrome(url);
		}

	}

	[Require("Xcode.Framework", "SafariServices")]
	[ForeignInclude(Language.ObjC, "AVFoundation/AVFoundation.h")]
	[Require("Source.Include", "UIKit/UIKit.h")]
	[Require("Source.Include", "SafariServices/SafariServices.h")]
	public extern(iOS) class Safari
	{
		[Foreign(Language.ObjC)]
		public static void PresentSafari(string url)
		@{
			NSURL* u = [[NSURL alloc] initWithString: url];
			SFSafariViewController* vc = [[SFSafariViewController alloc] initWithURL: u entersReaderIfAvailable:NO];
			dispatch_async(dispatch_get_main_queue(), ^{
				[[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:vc animated:YES completion:nil];
			});
		@}

	}

	[Require("Gradle.Dependency.Implementation", "androidx.browser:browser:1.0.0")]
	[ForeignInclude(Language.Java, "androidx.browser.customtabs.CustomTabsIntent", "android.net.Uri")]
	public extern(Android) class Chrome
	{

		[Foreign(Language.Java)]
		public static void PresentChrome(string url)
		@{
			CustomTabsIntent.Builder builder = new CustomTabsIntent.Builder();
			CustomTabsIntent customTabsIntent = builder.build();
			customTabsIntent.launchUrl(com.fuse.Activity.getRootActivity(), Uri.parse(url));
		@}
	}
}