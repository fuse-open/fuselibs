using Uno;
using Uno.Threading;
using Uno.Time;
using Uno.Collections;
using Uno.Permissions;
using Uno.Compiler.ExportTargetInterop;
using Fuse.GeoLocation.Android;

namespace Fuse.GeoLocation
{
	[ForeignInclude(Language.Java, "android.location.LocationManager", "android.location.Location", "android.util.Log", "java.util.List", "fuse.geolocation.UpdateListener", "android.os.Looper", "android.content.Context", "com.uno.StringArray")]
	extern(Android) class AndroidLocationProvider :  ILocationTracker
	{
		
		bool _authorized;
		bool _started;
		Action<Location> _onLocationChanged;
		Java.Object _locationManager;
		Java.Object _updateListener;
		Action _onReady;
		
		
		public AndroidLocationProvider() { }
		
		public void Init(Action onReady)
		{
			_onReady = onReady;
			var permissions = new PlatformPermission[] 
			{
				Permissions.Android.INTERNET,
				Permissions.Android.ACCESS_COARSE_LOCATION,
				Permissions.Android.ACCESS_FINE_LOCATION
			};
			
			Permissions.Request(permissions).Then(OnPermissionsResult, OnPermissionsError);
		}
		
		void OnPermissionsResult(PlatformPermission[] grantedPermissions)
		{
			_authorized = true;
			_locationManager = GetLocationManager();
			_updateListener = GetUpdateListener(OnLocationChanged);
			_onReady();
			_onReady = null;
		}
		
		void OnPermissionsError(Exception e)
		{
			_authorized = false;
			_onReady();
			_onReady = null;
		}
		
		[Foreign(Language.Java)]
		static Java.Object GetLocationManager()
		@{
			return com.fuse.Activity.getRootActivity().getSystemService(Context.LOCATION_SERVICE);
		@}
		
		[Foreign(Language.Java)]
		static Java.Object GetUpdateListener(Action<Java.Object> onLocationChanged)
		@{
			return new UpdateListener(onLocationChanged);
		@}

		public void RequestAuthorization(GeoLocationAuthorizationType type)
		{
		}
		
		[Foreign(Language.Java)]
		static bool IsNetworkEnabled(Java.Object locationManager)
		@{
			return ((LocationManager)locationManager).isProviderEnabled(LocationManager.NETWORK_PROVIDER);
		@}

		[Foreign(Language.Java)]
		static bool IsGPSEnabled(Java.Object locationManager)
		@{
			return ((LocationManager)locationManager).isProviderEnabled(LocationManager.GPS_PROVIDER);
		@}
		
		
		[Foreign(Language.Java)]
		static int GetNumProviders(Java.Object handle)
		@{
			return ((LocationManager)handle).getAllProviders().size();
		@}
		
		[Foreign(Language.Java)]
		static void ListProviders(Java.Object handle, string[] output)
		@{
			List<String> l = ((LocationManager)handle).getAllProviders();
			for(int i = 0; i<l.size(); i++)
				output.set(i, l.get(i));
		@}

		void OnLocationChanged(Java.Object location)
		{
			if(_onLocationChanged != null)
				_onLocationChanged(LocationHelpers.ConvertLocation(location));
		}	
		
		public void GetLocation(Promise<Location> promise, double timeout)
		{
			if (_locationManager == null) return;
			
			new PromiseListener(_locationManager, timeout, promise);
		}
		
		[Foreign(Language.Java)]
		static Java.Object GetLastKnownLocationFromProvider(Java.Object handle, string provider)
		@{
			return ((LocationManager)handle).getLastKnownLocation(provider);
		@}

		public Location GetLastKnownPosition()
		{
			if (_locationManager != null)
			{
				var locations = new List<Location>();
				string[] providers = new string[GetNumProviders(_locationManager)];
				ListProviders(_locationManager, providers);
				foreach(var provider in providers) 
				{
					var lo = GetLastKnownLocationFromProvider(_locationManager, provider);
					if(lo != null)
						locations.Add(LocationHelpers.ConvertLocation(lo));
				}
				var minTime = DateTime.UtcNow.Minus(Duration.FromHours(1)).ToInstant();
				return ChooseBestLocation(locations, 50, minTime);
			}
			return null;
		}
		
		Location ChooseBestLocation(IList<Location> locations, int minDistance, Instant minTime)
		{
			Location bestResult = null;
			double bestAccuracy = double.MaxValue;
			var bestTime = new Instant();

			foreach(var location in locations)
			{
				var accuracy = location.Accuracy;
				var time = location.DateTime.InUtc().ToInstant();

				if (time > minTime && accuracy < bestAccuracy)
				{
					bestResult = location;
					bestAccuracy = accuracy;
					bestTime = time;
				}
				else if (time < minTime && bestAccuracy == double.MaxValue && time > bestTime)
				{
					bestResult = location;
					bestTime = time;
				}
			}

			return bestResult;
		}
		
		[Foreign(Language.Java)]
		static void RequestNetworkLocationUpdates(Java.Object handle, int minimumReportInterval, double desiredAccuracyInMeters, Java.Object listener)
		@{
			((LocationManager)handle).requestLocationUpdates(LocationManager.NETWORK_PROVIDER, (long)minimumReportInterval, (float)desiredAccuracyInMeters, (UpdateListener)listener, Looper.getMainLooper());
		@}
		
		[Foreign(Language.Java)]
		static void RequestGPSLocationUpdates(Java.Object handle, int minimumReportInterval, double desiredAccuracyInMeters, Java.Object listener)
		@{
			((LocationManager)handle).requestLocationUpdates(LocationManager.GPS_PROVIDER, (long)minimumReportInterval, (float)desiredAccuracyInMeters, (UpdateListener)listener, Looper.getMainLooper());
		@}
		
		public void StartListening(Action<Location> onLocationChanged, Action<Uno.Exception> onLocationError, int minimumReportInterval, double desiredAccuracyInMeters)
		{
			if (_locationManager != null && !_started)
			{
				_onLocationChanged = onLocationChanged;
				
				if(IsNetworkEnabled(_locationManager))
					RequestNetworkLocationUpdates(_locationManager, minimumReportInterval, desiredAccuracyInMeters, _updateListener);
					
				if(IsGPSEnabled(_locationManager))
					RequestGPSLocationUpdates(_locationManager, minimumReportInterval, desiredAccuracyInMeters, _updateListener);

				_started = true;
			}
		}
		
		[Foreign(Language.Java)]
		static void RemoveUpdates(Java.Object manager, Java.Object listener)
		@{
			((LocationManager)manager).removeUpdates((UpdateListener)listener);
		@}
		
		public void StopListening()
		{
			RemoveUpdates(_locationManager, _updateListener);
			_started = false;
		}
	}
}
