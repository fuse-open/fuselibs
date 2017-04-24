using Uno.UX;
using Fuse.Scripting;
using Uno.Collections;

namespace Fuse.Reactive.FuseJS
{
	/**
		@scriptmodule FuseJS/InterApp

		The InterApp API allows you to launch other apps, as well as respond to being launched via URI schemes.

		This module is an @EventEmitter, so the methods from @EventEmitter can be used to listen to events.

		You need to add a reference to `"Fuse.Launcher"` in your project file to use this feature.

		## Example

			var InterApp = require("FuseJS/InterApp");

			InterApp.on("receivedUri", function(uri) {
				console.log("Launched with URI", uri);
			});

			InterApp.launchUri("https://www.fusetools.com/");

		In the above example we're using the @EventEmitter `on` method to listen to the `"receivedUri"` event.

		For the [receivedUri](api:fuse/reactive/fusejs/interapp/onreceiveduri_968f99a6.json) event to be triggered, you need register a custom URI scheme for your app, as shown [here](articles:basics/uno-projects#mobile-urischeme).

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

			See [the InterApp module](api:fuse/reactive/fusejs/interapp.json) for an example.
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
	}
}
