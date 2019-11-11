using Uno;
using Uno.UX;
using Fuse.Scripting;
using Uno.Compiler.ExportTargetInterop;

namespace FuseJS
{
	/**
		@scriptmodule FuseJS/Environment

		The Environment API allows you to check which platform your app is currently running on.

		You need to add a reference to `"FuseJS"` in your project file to use this feature.

		## Examples

		You can check which platform your app is running on using the following boolean properties:

			var Environment = require('FuseJS/Environment');

			if(Environment.ios)        console.log("Running on iOS");
			if(Environment.android)    console.log("Running on Android");
			if(Environment.preview)    console.log("Running in preview mode");
			if(Environment.mobile)     console.log("Running on iOS or Android");
			if(Environment.desktop)    console.log("Running on desktop");

		You can also get the version of the current *mobile* OS as a
		human-readable string using the `mobileOSVersion` property.

			console.log(Environment.mobileOSVersion);

		> *Note*
		>
		> On Android, `mobileOSVersion` returns [Build.VERSION.RELEASE](https://developer.android.com/reference/android/os/Build.VERSION.html#RELEASE)
		> (e.g. `1.0` or `3.4b5`).
		> On iOS, it returns a string in the format of `<major>.<minor>.<patch>`
		> (e.g. `9.2.1`).
		> Returns an empty string on all other platforms.

		@scriptproperty (bool) ios `true` if the app is running on iOS.
		@scriptproperty (bool) android `true` if the app is running on Android.
		@scriptproperty (bool) preview `true` if the app is running in either local or device previev.
		@scriptproperty (bool) mobile `true` if the app is running in a mobile OS.
		@scriptproperty (bool) desktop `true` if the app is running on a desktop OS.
		@scriptproperty (string) mobileOSVersion A user-readable OS version number.
			On Android, it returns [Build.VERSION.RELEASE](https://developer.android.com/reference/android/os/Build.VERSION.html#RELEASE)
			(e.g. `1.0` or `3.4b5`).
			On iOS, it returns a string in the format of `<major>.<minor>.<patch>` (e.g. `9.2.1`).
			Returns an empty string on all other platforms.
		@scriptproperty (string) locale Get current device locale using BCP47 format (e.g. `en-US`).
	*/
	[UXGlobalModule]
	public sealed class Environment : NativeModule
	{
		static readonly Environment _instance;

		public Environment()
		{
			if(_instance != null) return;
			Resource.SetGlobalKey(_instance = this, "FuseJS/Environment");
			AddMember(new NativeProperty<bool, bool>("android", defined(ANDROID)));
			AddMember(new NativeProperty<bool, bool>("ios", defined(iOS)));
			AddMember(new NativeProperty<bool, bool>("mobile", defined(MOBILE)));
			AddMember(new NativeProperty<bool, bool>("desktop", defined(!MOBILE)));
			AddMember(new NativeProperty<bool, bool>("preview", defined(DESIGNMODE)));
			AddMember(new NativeProperty<bool, bool>("dotnet", defined(DOTNET))); // Undocumented for testing use only
			AddMember(new NativeProperty<bool, bool>("host_mac", defined(HOST_MAC))); // Undocumented for testing use only
			AddMember(new NativeProperty<string, string>("mobileOSVersion", GetMobileOSVersion));
			AddMember(new NativeProperty<string, object>("locale", GetCurrentLocale));
		}

		static string GetMobileOSVersion()
		{
			if defined(iOS) return Fuse.iOSDevice.OperatingSystemVersion.ToString();
			if defined(Android) return Fuse.AndroidProperties.ReleaseVersion;
			return "";
		}

		[Foreign(Language.Java)]
		static extern(Android) string GetCurrentLocale()
		@{
			java.util.Locale loc = java.util.Locale.getDefault();

			final char separator = '-';
			String language = loc.getLanguage();
			String region = loc.getCountry();
			String variant = loc.getVariant();

			if (language.isEmpty() || !language.matches("\\p{Alpha}{2,8}")) {
				language = "und"; // "und" for Undetermined
			} else if (language.equals("in")) {
				language = "id";  // correct deprecated "Indonesian"
			}

			StringBuilder bcp47Tag = new StringBuilder(language);
			if (!region.isEmpty()) {
				bcp47Tag.append(separator).append(region);
			}

			if (!variant.isEmpty()) {
				bcp47Tag.append(separator).append(variant);
			}

			return bcp47Tag.toString();
		@}

		[Foreign(Language.ObjC)]
		static extern(iOS) string GetCurrentLocale()
		@{
			NSString* language = NSLocale.preferredLanguages[0];

			if (language.length <= 2)
			{
				NSLocale* locale = NSLocale.currentLocale;
				NSString* localeId = locale.localeIdentifier;
				NSRange underscoreIndex = [localeId rangeOfString: @"_" options: NSBackwardsSearch];
				NSRange atSignIndex = [localeId rangeOfString: @"@"];

				if (underscoreIndex.location != NSNotFound)
				{
					if (atSignIndex.length == 0)
						language = [NSString stringWithFormat: @"%@%@", language, [localeId substringFromIndex: underscoreIndex.location]];
					else
					{
						NSRange localeRange = NSMakeRange(underscoreIndex.location, atSignIndex.location - underscoreIndex.location);
						language = [NSString stringWithFormat: @"%@%@", language, [localeId substringWithRange: localeRange]];
					}
				}
			}

			return [language stringByReplacingOccurrencesOfString: @"_" withString: @"-"];
		@}

		static extern(!Mobile) string GetCurrentLocale()
		{
			return "en-US";
		}
	}
}
