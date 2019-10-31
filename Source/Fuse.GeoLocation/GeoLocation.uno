using Uno;
using Uno.UX;
using Uno.Text;
using Uno.Threading;
using Fuse.Scripting;
using Fuse.GeoLocation;

namespace Fuse.GeoLocation
{
	[UXGlobalModule]
	/**
		@scriptmodule FuseJS/GeoLocation

		Provides geolocation services.

		Using geolocation services requires device authorization. Including the `Fuse.GeoLocation` package
		in your project will trigger a prompt for this authorization when the app is launched.

		Use [startListening](api:fuse/geolocation/geolocation/startlistening_bbef95e2.json)
		to get continual location updates. Use
		[location](api:fuse/geolocation/geolocation/getlocation.json)
		or [getLocation](api:fuse/geolocation/geolocation/getlocationasync_95a738ba.json) for one-time location requests.

		You need to add a reference to `"Fuse.GeoLocation"` in your project file to use this feature.

		This module is an @EventEmitter, so the methods from @EventEmitter can be used to listen to events.

		## Example

		The following example shows how the different modes of operation can be used:

			<JavaScript>
				var Observable = require("FuseJS/Observable");
				var GeoLocation = require("FuseJS/GeoLocation");

				// Immediate
				var immediateLocation = JSON.stringify(GeoLocation.location);

				// Timeout
				var timeoutLocation = Observable("");
				var timeoutMs = 5000;
				GeoLocation.getLocation(timeoutMs).then(function(location) {
					timeoutLocation.value = JSON.stringify(location);
				}).catch(function(fail) {
					console.log("getLocation fail " + fail);
				});

				// Continuous
				var continuousLocation = GeoLocation.observe("changed").map(JSON.stringify);

				GeoLocation.on("error", function(fail) {
					console.log("GeoLocation error " + fail);
				});

				function startContinuousListener() {
					var intervalMs = 1000;
					var desiredAccuracyInMeters = 10;
					GeoLocation.startListening(intervalMs, desiredAccuracyInMeters);
				}

				function stopContinuousListener() {
					GeoLocation.stopListening();
				}

				module.exports = {
					immediateLocation: immediateLocation,
					timeoutLocation: timeoutLocation,
					continuousLocation: continuousLocation,

					startContinuousListener: startContinuousListener,
					stopContinuousListener: stopContinuousListener
				};
			</JavaScript>

			<StackPanel>
				<Text>Immediate:</Text>
				<Text Value="{immediateLocation}" />

				<Text>Timeout:</Text>
				<Text Value="{timeoutLocation}" />

				<Text>Continuous:</Text>
				<Text Value="{continuousLocation}" />

				<Button Text="Start continuous listener" Clicked="{startContinuousListener}" />
				<Button Text="Stop continuous listener" Clicked="{stopContinuousListener}" />
			</StackPanel>

		In the above example we're using the @EventEmitter `observe` method to create an @Observable from the
		`"changed"` event. We can also listen to changes by using the `on` method, as follows:

			GeoLocation.on("changed", function(location) { ... })

		Locations returned by this module are JavaScript objects of the following form:

			{
				latitude: a number measured in decimal degrees,
				longitude: a number measured in decimal degrees,
				accuracy: a number measured in meters
			}

		To handle errors from GeoLocation we can listen to the `"error"` event, as follows:

			GeoLocation.on("error", function(err) { ... })
	*/
	public sealed class GeoLocation : NativeEventEmitterModule
	{
		LocationTracker _locationTracker;
		static readonly GeoLocation _instance;

		public GeoLocation()
			: base(false,
				"changed")
		{
			if(_instance != null) return;
			Resource.SetGlobalKey(_instance = this, "FuseJS/GeoLocation");
			_locationTracker = new LocationTracker();

			// Old-style events for backwards compatibility
			var onChangedEvent = new NativeEvent("onChanged");
			var onErrorEvent = new NativeEvent("onError");

			On("changed", onChangedEvent);
			// Note: If we decide to remove these old-style events in the future, the
			// "error" event will no longer have a listener by default, meaning that the
			// module will then throw an exception on "error" (as per the way
			// EventEmitter works), unlike the current behaviour.  To retain the current
			// behaviour we might then want to add a dummy listener to the "error"
			// event.
			On("error", onErrorEvent);

			AddMember(onChangedEvent);
			AddMember(onErrorEvent);

			AddMember(new NativeFunction("isLocationEnabled", (NativeCallback)IsLocationEnabled));
			AddMember(new NativeProperty<string, object>("authorizationStatus", GetAuthorizationStatus));
			AddMember(new NativeProperty<Fuse.GeoLocation.Location, Scripting.Object>("location", GetLocation, null, Converter));
			AddMember(new NativePromise<Fuse.GeoLocation.Location, Scripting.Object>("getLocation", GetLocationAsync, Converter));
			AddMember(new NativeProperty<Fuse.GeoLocation.GeoLocationAuthorizationType, int>("authorizationRequest", GetAuthorizationRequest, SetAuthorizationRequest, AuthorizationRequestConverter));
			AddMember(new NativeFunction("startListening", (NativeCallback)StartListening));
			AddMember(new NativeFunction("stopListening", (NativeCallback)StopListening));

			_locationTracker.LocationChanged += LocationChanged;
			_locationTracker.LocationError += LocationError;
		}

		/** @scriptmethod isLocationEnabled() 
		Returns whether or not the device has Geolocation enabled.
		*/
		object IsLocationEnabled(Context context, object[] args) 
		{
			return _locationTracker.IsLocationEnabled();
		}

		/** @scriptmethod GetAuthorizationStatus() 
		Returns the authorization status of GeoLocation
		*/
		string GetAuthorizationStatus() 
		{
			return _locationTracker.GetAuthorizationStatus();
		}


		/**
			@scriptmethod startListening(minimumReportInterval, desiredAccuracy)

			Starts the GeoLocation listening service.
			
			[onChanged](api:fuse/geolocation/geolocation/locationchanged_adbb1cba.json)
			events will be generated as the location changes.


			Use [stopListening](api:fuse/geolocation/geolocation/stoplistening_bbef95e2.json) to stop the service.
			
			The parameters here are desired values; the actual interval and accuracy are dependent on the
			device.

			See [the GeoLocation module](api:fuse/geolocation/geolocation) for an example.

			@param minimumReportInterval how often the position should be updated. Value in milliseconds
			@param desiredAccuracy how accurate, in meters, should the values be
			
		*/
		object StartListening(Context c, object[] args)
		{
			var minimumReportInterval = (args.Length > 0) ? Marshal.ToInt(args[0]) : 0;
			var desiredAccuracyInMeters = (args.Length > 1) ? Marshal.ToDouble(args[1]) : 0;

			_locationTracker.StartListening(minimumReportInterval, desiredAccuracyInMeters);
			return null;
		}
		
		/**
			@scriptmethod stopListening()

			Stops the GeoLocation listening service.

			See [the GeoLocation module](api:fuse/geolocation/geolocation) for an example.
		*/
		object StopListening(Context c, object[] args)
		{
			_locationTracker.StopListening();
			return null;
		}

		/**
			@scriptevent changed(location)

			Raised when the location changes.

			Use [startListening](api:fuse/geolocation/geolocation/startlistening_bbef95e2.json) to get these events.

			The parameter object is of the following form:

				{
					altitude: altitude measured in meters,
					latitude: a number measured in decimal degrees,
					longitude: a number measured in decimal degrees,
					accuracy: a number measured in meters,
					speed: speed measured in meters per second
				}

			See [the GeoLocation module](api:fuse/geolocation/geolocation) for an example.

			@param location will contain the new location, see @location
		*/
		void LocationChanged(Fuse.GeoLocation.Location location)
		{
			EmitFactory(ChangedArgsFactory, location);
		}

		static object[] ChangedArgsFactory(Context context, Fuse.GeoLocation.Location location)
		{
			return new object[] { "changed", Converter(context, location) };
		}
		
		/**
			@scriptevent error(error)

			Raised when an error occurs.

			@param error a string describing the error
		*/
		void LocationError(string error)
		{
			EmitError(error);
		}
		
		static int AuthorizationRequestConverter(Context context, Fuse.GeoLocation.GeoLocationAuthorizationType type)
		{
			return (int)type;
		}

		/**
			@scriptproperty authorizationRequest

			@param value (int) Set the authorization request type
				1 = When in use (default)
				2 = Always

			The type of authorization request to make to the user.


			This property currently only affects iOS. It should be
			set before using the rest of the GeoLocation API.

			Setting this property to `1`, which is also the
			default, for example as follows:

				var GeoLocation = require("FuseJS/GeoLocation");
				GeoLocation.authorizationRequest = 1;

			Means that the app should request permission from the
			user to use location services while the app is in the
			foreground. Setting it to `2`, as follows:

				GeoLocation.authorizationRequest = 2;

			Means that the app should request permission from the
			user to use location services whenever the app is
			running.
		*/
		void SetAuthorizationRequest(int value)
		{
			_locationTracker.AuthorizationType = (GeoLocationAuthorizationType)value;
		}

		Fuse.GeoLocation.GeoLocationAuthorizationType GetAuthorizationRequest()
		{
			return _locationTracker.AuthorizationType;
		}

		/**
			@scriptproperty location
			@readonly

			The last known location.

			The returned object is of the following form:

				{
					altitude: altitude measured in meters,
					latitude: a number measured in decimal degrees,
					longitude: a number measured in decimal degrees,
					accuracy: a number measured in meters,
					speed: speed measured in meters per second
				}

			See [the GeoLocation module](api:fuse/geolocation/geolocation) for an example.
		*/
		Fuse.GeoLocation.Location GetLocation()
		{
			return _locationTracker.Location;
		}
		
		/**
			@scriptmethod getLocation(timeout)

			@param timeout (int) Optional timeout in milliseconds
			@return a promise

			Gets the current location as a promise.
			
			Can optionally be passed a timeout (in milliseconds)
			that the promise should be rejected after.

			If successful, the promise is resolved with an object of the following form:

				{
					altitude: altitude measured in meters,
					latitude: a number measured in decimal degrees,
					longitude: a number measured in decimal degrees,
					accuracy: a number measured in meters,
					speed: speed measured in meters per second
				}

			See [the GeoLocation module](api:fuse/geolocation/geolocation) for an example.
		*/
		Future<Fuse.GeoLocation.Location> GetLocationAsync(object[] args)
		{
			double timeout = (args.Length > 0) ? Marshal.ToDouble(args[0]) : 20000;
			return _locationTracker.GetLocationAsync(timeout);
		}

		static Scripting.Object Converter(Context context, Fuse.GeoLocation.Location location)
		{
			var obj = context.NewObject();
			if(location != null)
			{
				obj["latitude"] = location.Coordinates.Latitude;
				obj["longitude"] = location.Coordinates.Longitude;
				obj["accuracy"] = location.Accuracy;
				obj["altitude"] = location.Altitude;
				obj["speed"] = location.Speed;
			}
			return obj;
		}
	}
}
