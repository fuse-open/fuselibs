using Uno.UX;
using Fuse.Scripting;

namespace Fuse.Reactive.FuseJS
{
	/**
		@scriptmodule FuseJS/InterApp

		The InterApp API allows you to launch other apps, as well as respond to being launched via URI schemes.

		This module is an @EventEmitter, so the methods from @EventEmitter can be used to listen to events.

		You need to add a reference to `"Fuse.Launcher"` in your project file to use this feature.

		## Example
		```javascript
			var InterApp = require("FuseJS/InterApp");

			InterApp.on("receivedUri", function(uri) {
				console.log("Launched with URI", uri);
			});

			InterApp.launchUri("https://fuseopen.com/");
		```

		In the above example we're using the @EventEmitter `on` method to listen to the `"receivedUri"` event.

		For the [receivedUri](api:fuse/reactive/fusejs/interapp/onreceiveduri_968f99a6.json) event to be triggered, you need register a custom URI scheme for your app, as shown [here](articles:basics/uno-projects#mobile-urischeme).

				
		## Deep Links - Universal and App Links

		You can receive the `receivedUri` event, mentioned above, for associated web urls that have been tapped on in other apps.

		Apple: [https://developer.apple.com/ios/universal-links](https://developer.apple.com/ios/universal-links)

		Android: [https://developer.android.com/training/app-links](https://developer.android.com/training/app-links)

		## Apple Universal Links
				
		1. Add the associated domains in your `.unoproj`
		2. Add the Apple App Site Association file to your website

		### 1. Add associated domains to your .unoproj

		```JSON
		{
			"iOS": {
				"SystemCapabilities": {
					"AssociatedDomains": ["applinks:example.com", "applinks:sub.example.com"]
				}
			}
		}
		```

		### 2. Add the Apple App Site Association file to your website

		Apple-app-site-association file format
		```JSON
		{
			"applinks": {
				"apps": [],
				"details": [
					{
						"appID": "<team identifier>.<bundle identifier>",
						"paths": [<paths>]
					}
				]
			}
		}
		```

		Basic example, this allows all urls of the domain to be validated:
		```JSON
		{
			"applinks": {
				"apps": [],
				"details": [
					{
						"appID": "1234567890.com.mypackage.myapp",
						"paths": ["*"]
					}
				]
			}
		}
		```


		Place this file either in your site’s `.well-known` directory, or directly in its root directory. If you use the `.well-known` directory, the file’s URL should match the following format:
		```
		https://<fully qualified domain>/.well-known/apple-app-site-association
		```
		Tip: make sure you can access the file and view the JSON of the apple-app-site-association file from a browser.

		Full reference: [https://developer.apple.com/documentation/uikit/inter-process_communication/allowing_apps_and_websites_to_link_to_your_content/enabling_universal_links?language=objc](https://developer.apple.com/documentation/uikit/inter-process_communication/allowing_apps_and_websites_to_link_to_your_content/enabling_universal_links?language=objc)

		## Android App Links

		1. Add the associated domains in your `.unoproj`
		2. Add the asset links file to your website

		### 1. Add associated domains to your .unoproj

		```JSON
		{
			"Android": {
				"AssociatedDomains": ["example.com", "sub.example.com"]
			}
		}
		```

		### 2. Add the asset links file to your website
		
		Example:
		```
		[{
		  "relation": ["delegate_permission/common.handle_all_urls"],
		    "target": {
		      "namespace": "android_app",
		      "package_name": "com.example.puppies.app",
		      "sha256_cert_fingerprints":
		      ["14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64:16:A0:83:42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:44:E5"]
		    }
		  },
		  {
		    "relation": ["delegate_permission/common.handle_all_urls"],
		    "target": {
		      "namespace": "android_app",
		      "package_name": "com.example.monkeys.app",
		      "sha256_cert_fingerprints":
		      ["14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64:16:A0:83:42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:44:E5"]
		    }
		}]
		```

		Each group represents an app, you will likely need one for your development version and one for your release version of your app.

		To get the `sha256_cert_fingerprints`, use the following:
		```
		keytool -list -v -keystore my-release-key.keystore
		```

		To get the sha256 for the development version of exporting with fuse, use with `android` as the password:
		`keytool -list -v -keystore ~/.android/debug.keystore`

		Place this file in your site’s `.well-known` directory. The file’s URL should match the following format:
		```
		https://domain.name/.well-known/assetlinks.json
		```
	*/
	[UXGlobalModule]
	public sealed class InterApp : NativeEventEmitterModule
	{
		static readonly InterApp _instance;

		public InterApp()
			: base(true,
				"receivedUri")
		{
			if(_instance != null) return;
			Resource.SetGlobalKey(_instance = this, "FuseJS/InterApp");
			var onReceivedUri = new NativeEvent("onReceivedUri");

			On("receivedUri", onReceivedUri);

			AddMember(onReceivedUri);
			AddMember(new NativeFunction("launchUri", LaunchUri));
			AddMember(new NativeFunction("launchApp", LaunchApp));

			Fuse.Platform.InterApp.ReceivedURI += OnReceivedUri;
		}

		/**
			@scriptevent receivedUri
			@param uri (String) The URI to launch
			Called when the app is launched via its own URI scheme.

			For this to be called, you need register a custom URI scheme for your app, as shown [here](/docs/basics/uno-projects#mobile-urischeme).

			See [the InterApp module](api:fuse/reactive/fusejs/interapp.json) for an example.
		*/
		void OnReceivedUri(string uri)
		{
			Emit("receivedUri", uri);
		}

		/**
			@scriptmethod launchUri(uri)
			@param uri (String) The URI to launch.

			Requests the system to launch an app that handles the specified URI.

			Note: you can pass any URI string to `launchUri`, but how it is handled will depend on the target platform and particular device settings.

			There are several common URI schemes that you can use on both Android and iOS:
				http://<website address>
				https://<website address>
				tel:<phone number>
				sms:<phone number>

			Other platform-specific URI schemes are known to be working fine, for example `geo:<parameters>` launches Maps application on Android
			and `facetime:<parameters>` launches a Facetime video call on iOS.
			More information on supported URI schemes: [on Android](https://developer.android.com/guide/components/intents-common.html) and [on iOS](https://developer.apple.com/library/content/featuredarticles/iPhoneURLScheme_Reference/Introduction/Introduction.html).
		*/
		public static object LaunchUri(Scripting.Context context, object[] args)
		{
			// using 'launch' as name because:
			// - open implies the app may not already be open
			// - call implies there could be a response
			// - send just feels wrong :p

			Fuse.LauncherImpl.InterAppLauncher.LaunchUri(new Uno.Net.Http.Uri((string)args[0]));
			return null;
		}

		/**
			@scriptmethod launchApp(uri)
			@param uri (String) The URI to launch or application id(android) to launch.

			Requests the system to launch an app.

			Note: for iOS you must use a uri
			for android, an applicationid like: https://play.google.com/store/apps/details?id=[application id]

			There are several common URI schemes that you can use on iOS:
				http://<website address>
				https://<website address>
				tel:<phone number>
				sms:<phone number>
			
			More information on supported URI schemes on iOS(https://developer.apple.com/library/content/featuredarticles/iPhoneURLScheme_Reference/Introduction/Introduction.html).
		*/
		public static object LaunchApp(Scripting.Context context, object[] args)
		{
			if defined(Android)
			{
				Fuse.LauncherImpl.InterAppLauncher.LaunchApp((string)args[0]);
			}
			if defined(iOS)
			{
				Fuse.LauncherImpl.InterAppLauncher.LaunchApp((string)args[0], (string)args[1]);
			}
			return null;
		}
	}
}
