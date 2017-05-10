using Uno;
using Uno.UX;
using Fuse.Scripting;

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
			AddMember(new NativeProperty<string, string>("mobileOSVersion", GetMobileOSVersion));
		}
		
		static string GetMobileOSVersion()
		{
			if defined(iOS) return Fuse.iOSDevice.OperatingSystemVersion.ToString();
			if defined(Android) return Fuse.AndroidProperties.ReleaseVersion;
			return "";
		}
	}
}
