using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Uno.Threading;
using Uno;

namespace Fuse.GeoLocation
{
	[Require("Xcode.Framework", "CoreLocation")]
	[ForeignInclude(Language.ObjC, "CoreLocation/CoreLocation.h")]
	[ForeignInclude(Language.ObjC, "iOS/LocationManagerDelegate.h")]
	extern(iOS) class IOSLocationProvider : ILocationTracker
	{
		private const int AuthorizedWhenInUse = 4;

		ObjC.Object _lm; // CLLocationManager*
		ObjC.Object _lmDelegate; // LocationManagerDelegate*
		Action<Location> _continuousLocationListener;
		Action<Exception> _continuousErrorListener;
		Queue<Promise<Location>> _waitingPromises = new Queue<Promise<Location>>();
		Promise<Location> _currentWaitingPromise;
		double _promiseTimeout;
		double _desiredAccuracyInMeters;

		[Foreign(Language.ObjC)]
		public IOSLocationProvider()
		@{
			CLLocationManager* lm = [[CLLocationManager alloc] init];
			NSArray* backgroundModes  = [[NSBundle mainBundle].infoDictionary objectForKey:@"UIBackgroundModes"];

		    if(backgroundModes && [backgroundModes containsObject:@"location"]) {
		        if([lm respondsToSelector:@selector(setAllowsBackgroundLocationUpdates:)]) {
		            // We now have iOS9 and the right capabilities to set this:
					lm.allowsBackgroundLocationUpdates = true;
		        }
		    }

			lm.pausesLocationUpdatesAutomatically = false;
			LocationManagerDelegate* lmDelegate = [[LocationManagerDelegate alloc] initWithBlock: ^void (CLLocation* location)
			{
				@{IOSLocationProvider:Of(_this).OnLocationChanged(ObjC.Object):Call(location)};
			}
			error: ^void (NSError* err)
			{
				@{IOSLocationProvider:Of(_this).OnError(string):Call(err.localizedDescription)};
			}
			changeAuthorizationStatus: ^void (int status)
			{
				@{IOSLocationProvider:Of(_this).OnChangeAuthorizationStatus(int):Call(status)};
			}
			];

			lm.delegate = lmDelegate;

			@{IOSLocationProvider:Of(_this)._lm:Set(lm)};
			@{IOSLocationProvider:Of(_this)._lmDelegate:Set(lmDelegate)};
		@}

		void OnLocationChanged(ObjC.Object clLocation)
		{
			var location = ConvertLocation(clLocation);

			if (_continuousLocationListener != null)
				_continuousLocationListener(location);

			var promisesResolved = _waitingPromises.Count > 0;
			while (_waitingPromises.Count > 0)
			{
				var p = _waitingPromises.Dequeue();
				if (p.State == FutureState.Pending)
					p.Resolve(location);
			}
			if (promisesResolved)
				OnListenerRemoved();
		}

		void OnError(string errorString)
		{
			var exception = new Exception(errorString);

			if (_continuousErrorListener != null)
				_continuousErrorListener(exception);

			var promisesResolved = _waitingPromises.Count > 0;
			while (_waitingPromises.Count > 0)
			{
				var p = _waitingPromises.Dequeue();
				if (p.State == FutureState.Pending)
					p.Reject(exception);
			}
			if (promisesResolved)
				OnListenerRemoved();
		}

		void OnListenerRemoved()
		{
			// Restore the desired accuracy in case it was set from GetLocation
			if (_continuousLocationListener != null || _continuousErrorListener != null)
			{
				SetCLLocationManagerParams(_lm, _desiredAccuracyInMeters);
			}
			else if (_waitingPromises.Count == 0)
			{
				StopUpdatingLocation(_lm);
			}
		}

		public void StartListening(
			Action<Location> onLocationChanged,
			Action<Exception> onLocationError,
			int minimumReportInterval,
			double desiredAccuracyInMeters)
		{
			_desiredAccuracyInMeters = desiredAccuracyInMeters;
			_continuousLocationListener = onLocationChanged;
			_continuousErrorListener = onLocationError;
			// There's no setting for report interval on iOS, so we ignore it
			SetCLLocationManagerParams(_lm, _desiredAccuracyInMeters);
			StartUpdatingLocation(_lm);
		}


		[Foreign(Language.ObjC)]
		public bool IsLocationEnabled() 
		@{
			//check is hardware enabled
			if ([CLLocationManager locationServicesEnabled]) {

				//check user authorization
				switch ([CLLocationManager authorizationStatus]) {
					case kCLAuthorizationStatusAuthorizedAlways:
					case kCLAuthorizationStatusAuthorizedWhenInUse: return true;
						break;
					default: return false;
						break;
				}
			} else {
				return false;
			}
		@}

		[Foreign(Language.ObjC)]
		public string GetAuthorizationStatus() 
		@{
			//check user authorization
			switch ([CLLocationManager authorizationStatus]) {
				//The user has not chosen whether the app can use location services.
				case kCLAuthorizationStatusNotDetermined: return @"notDetermined";
					break;
				//The app is not authorized to use location services.
				case kCLAuthorizationStatusRestricted: return @"restricted";
					break;
				//The user denied the use of location services for the app or they are disabled globally in Settings.
				case kCLAuthorizationStatusDenied: return @"denied";
					break;
				//The user authorized the app to start location services at any time.
				case kCLAuthorizationStatusAuthorizedAlways: return @"authorizedAlways";
					break;
				//The user authorized the app to start location services while it is in use.
				case kCLAuthorizationStatusAuthorizedWhenInUse: return @"authorizedWhenInUse";
					break;
			}
		@}

		[Foreign(Language.ObjC)]
		static void SetCLLocationManagerParams(
			ObjC.Object handle,
			double desiredAccuracyInMeters)
		@{
			CLLocationManager* lm = (CLLocationManager*)handle;
			lm.desiredAccuracy = desiredAccuracyInMeters;
		@}

		[Foreign(Language.ObjC)]
		static void StartUpdatingLocation(ObjC.Object handle)
		@{
			CLLocationManager* lm = (CLLocationManager*)handle;
			[lm startUpdatingLocation];
		@}

		public void StopListening()
		{
			_continuousLocationListener = null;
			_continuousErrorListener = null;
			OnListenerRemoved();
		}

		[Foreign(Language.ObjC)]
		static void StopUpdatingLocation(ObjC.Object handle)
		@{
			CLLocationManager* lm = (CLLocationManager*)handle;
			[lm stopUpdatingLocation];
		@}

		public void RequestAuthorization(GeoLocationAuthorizationType type)
		{
			RequestAuthorization(_lm, type);
		}

		[Foreign(Language.ObjC)]
		static void RequestAuthorization(ObjC.Object handle, GeoLocationAuthorizationType type)
		@{
			CLLocationManager* lm = (CLLocationManager*)handle;

			if (type == @{GeoLocationAuthorizationType.WhenInUse} &&
				[lm respondsToSelector:@selector(requestWhenInUseAuthorization)])
					[lm requestWhenInUseAuthorization];

			if (type == @{GeoLocationAuthorizationType.Always} &&
				[lm respondsToSelector:@selector(requestAlwaysAuthorization)])
					[lm requestAlwaysAuthorization];
		@}

		public Location GetLastKnownPosition()
		{
			return ConvertLocation(GetLastKnownPosition(_lm));
		}

		[Foreign(Language.ObjC)]
		static ObjC.Object GetLastKnownPosition(ObjC.Object handle)
		@{
			return ((CLLocationManager*)handle).location;
		@}

		public void GetLocation(Promise<Location> promise, double timeout)
		{
			SetCLLocationManagerParams(_lm, 0);
			// Stopping and starting triggers a new callback
			StopUpdatingLocation(_lm);
			StartUpdatingLocation(_lm);
			if (IsLocationPermitted())
			{
				PublishLocationPromise(promise, timeout);
			}
			else
			{
				RequestAuthorization(GeoLocationAuthorizationType.WhenInUse);
				_currentWaitingPromise = promise;
				_promiseTimeout = timeout;
			}
		}

		void OnChangeAuthorizationStatus(int clAuthorizationStatus)
		{
			if (clAuthorizationStatus == AuthorizedWhenInUse && _currentWaitingPromise != null)
			{
				PublishLocationPromise(_currentWaitingPromise, _promiseTimeout);
			}
		}

		private void PublishLocationPromise(Promise<Location> promise, double timeout)
		{
			Timer.Wait(timeout / 1000, new The(promise).TimedOut);
			_waitingPromises.Enqueue(promise);
		}

		[Foreign(Language.ObjC)]
		private bool IsLocationPermitted()
		@{
			return [CLLocationManager authorizationStatus]==kCLAuthorizationStatusAuthorizedWhenInUse;
		@}

		class The
		{
			readonly Promise<Location> _promise;

			public The(Promise<Location> promise)
			{
				_promise = promise;
			}

			public void TimedOut()
			{
				if (_promise.State == FutureState.Pending)
					_promise.Reject(new Exception("Location request timed out"));
			}
		}

		static Location ConvertLocation(ObjC.Object location)
		{
			double timeIntervalSince1970, latitude, longitude, horizontalAccuracy, altitude, speed;
			GetCLLocationProperties(
				location,
				out timeIntervalSince1970,
				out latitude,
				out longitude,
				out horizontalAccuracy,
				out altitude,
				out speed);

			var instant = Uno.Time.Instant.FromMillisecondsSinceUnixEpoch((long)timeIntervalSince1970 * 1000);
			var dateTime = new Uno.Time.LocalDateTime(instant, Uno.Time.CalendarSystem.Iso);
			return new Location(new GeoCoordinates(latitude, longitude), horizontalAccuracy, altitude, speed, dateTime);
		}

		[Foreign(Language.ObjC)]
		static void GetCLLocationProperties(
			ObjC.Object handle,
			out double timeIntervalSince1970,
			out double latitude,
			out double longitude,
			out double horizontalAccuracy,
			out double altitude,
			out double speed)
		@{
			CLLocation* location = (CLLocation*)handle;
			*timeIntervalSince1970 = location.timestamp.timeIntervalSince1970;
			*latitude = location.coordinate.latitude;
			*longitude = location.coordinate.longitude;
			*horizontalAccuracy = location.horizontalAccuracy;
			*altitude = location.altitude;
			*speed = location.speed;
		@}

		public void Init(Action onReady)
		{
			onReady();
		}
	}
}
