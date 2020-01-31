using Uno;
using Uno.Threading;
using Uno.Time;
using Uno.Collections;
using Uno.Permissions;
using Uno.Compiler.ExportTargetInterop;
using Fuse.GeoLocation.Android;

namespace Fuse.GeoLocation
{
	[ForeignInclude(Language.Java, 
		"androidx.core.content.ContextCompat", 
		"android.content.pm.PackageManager", 
		"android.Manifest", 
		"android.location.LocationManager", 
		"android.location.Location", 
		"android.provider.Settings", 
		"android.util.Log", 
		"java.util.List", 
		"fuse.geolocation.UpdateListener", 
		"fuse.geolocation.BackgroundService", 
		"android.content.Intent", 
		"android.os.Looper", 
		"android.content.Context", 
		"com.uno.StringArray")]
	extern(Android) class AndroidLocationProvider :  ILocationTracker
	{
		
		bool _authorized;
		bool _started;
		Action<Location> _onLocationChanged;
		Java.Object _locationManager;
		Java.Object _updateListener;
		Action _onReady;
		
		Action<Location> startListening_onLocationChanged;
		int startListening_minimumReportInterval;
		double startListening_desiredAccuracyInMeters;
		
		public AndroidLocationProvider() { }
		
		public void Init(Action onReady)
		{
			_onReady = onReady;

			if (@(Project.Android.GeoLocation.RequestPermissionsOnLaunch:ToLower) == "false") 
			{
				_authorized = false;
				_locationManager = GetLocationManager();
				_updateListener = GetUpdateListener(OnLocationChanged);
				_onReady();
				_onReady = null;
			} 
			else 
			{
				RequestPermissions();
			}
			
		}


		[Foreign(Language.Java)]
		static int checkPermissions() 
		@{	
			//check if background location is explicitly requested (not enabled by default since Android Q)
			if ("@(Project.Android.GeoLocation.BackgroundLocation.Enabled:ToLower)" == "true"
				&& android.os.Build.VERSION.SDK_INT >= 29) 
			{
				if (ContextCompat.checkSelfPermission(com.fuse.Activity.getRootActivity(), android.Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED 
					&& ContextCompat.checkSelfPermission(com.fuse.Activity.getRootActivity(), android.Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED)
				{
					if (ContextCompat.checkSelfPermission(com.fuse.Activity.getRootActivity(), android.Manifest.permission.ACCESS_BACKGROUND_LOCATION) == PackageManager.PERMISSION_GRANTED)
					{
						//already have all access
						return 0;
					}
					else
					{
						//request background permission
						return 1;
					}
				} 
				else
				{
					//request all permissions
					return 2;
				}
			} 
			else 
			{
				//request regular permissions
				return 3;
			}
		@}

		void RequestPermissions()
		{
			int permissionState = checkPermissions();

			switch (permissionState) {
				case 3:	
					var permissions = new PlatformPermission[] 
					{
						Permissions.Android.INTERNET,
						Permissions.Android.ACCESS_COARSE_LOCATION,
						Permissions.Android.ACCESS_FINE_LOCATION
					};
					Permissions.Request(permissions).Then(OnPermissionsResult, OnPermissionsError);
					break;
				case 2: 
					var permissions = new PlatformPermission[] 
					{
						Permissions.Android.INTERNET,
						Permissions.Android.ACCESS_COARSE_LOCATION,
						Permissions.Android.ACCESS_FINE_LOCATION,
						Permissions.Android.ACCESS_BACKGROUND_LOCATION
					};
					Permissions.Request(permissions).Then(OnPermissionsResult, OnPermissionsError);
					break;
				case 1: 
					var permissions = new PlatformPermission[] 
					{
						Permissions.Android.INTERNET,
						Permissions.Android.ACCESS_BACKGROUND_LOCATION
					};
					Permissions.Request(permissions).Then(OnPermissionsResult, OnPermissionsError);
					break;
				case 0:
					break;
			}
			
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
		public bool IsLocationEnabled() 
		@{
			android.location.LocationManager locationManager = (LocationManager)com.fuse.Activity.getRootActivity().getSystemService(Context.LOCATION_SERVICE);

			if (locationManager != null) 
			{
				if (android.os.Build.VERSION.SDK_INT >= 23) 
				{
					//check if background location is explicitly requested (not enabled by default since Android Q)
					if ("@(Project.Android.GeoLocation.BackgroundLocation.Enabled:ToLower)" == "true"
						&& android.os.Build.VERSION.SDK_INT >= 29) 
					{
						//check if hardware enabled
						if (locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)||locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER))
						{
							//check user authorization 
							if (ContextCompat.checkSelfPermission(com.fuse.Activity.getRootActivity(), android.Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED 
								&& ContextCompat.checkSelfPermission(com.fuse.Activity.getRootActivity(), android.Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED
								&& ContextCompat.checkSelfPermission(com.fuse.Activity.getRootActivity(), android.Manifest.permission.ACCESS_BACKGROUND_LOCATION) != PackageManager.PERMISSION_GRANTED) 
							{
								return false;
							} 
							else 
							{
								return true;
							}
						} 
						else 
						{
							return false;
						}
					} 
					else 
					{
						//check if hardware enabled
						if (locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)||locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER))
						{
							//check user authorization 
							if (ContextCompat.checkSelfPermission(com.fuse.Activity.getRootActivity(), android.Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED 
								&& ContextCompat.checkSelfPermission(com.fuse.Activity.getRootActivity(), android.Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) 
							{
								return false;
							} 
							else 
							{
								return true;
							}
						} 
						else 
						{
							return false;
						}
					}
				} 
				else 
				{
					//legacy fallback
					try 
					{
						locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER);
						return true;
					} 
					catch (SecurityException e) 
					{
						return false;
					}
				}
			} 
			else 
			{
				return false;
			}
		@}

		[Foreign(Language.Java)]
		public string GetAuthorizationStatus() 
		@{
			if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) //API 28
			{ 
				android.location.LocationManager lm = (android.location.LocationManager) com.fuse.Activity.getRootActivity().getSystemService(Context.LOCATION_SERVICE);

				if (lm.isLocationEnabled()) {

					//check if background location is explicitly requested (not enabled by default since Android Q)
					if ("@(Project.Android.GeoLocation.BackgroundLocation.Enabled:ToLower)" == "true"
						&& android.os.Build.VERSION.SDK_INT >= 29) 
					{
						if (ContextCompat.checkSelfPermission(com.fuse.Activity.getRootActivity(), android.Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED 
							&& ContextCompat.checkSelfPermission(com.fuse.Activity.getRootActivity(), android.Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED
							&& ContextCompat.checkSelfPermission(com.fuse.Activity.getRootActivity(), android.Manifest.permission.ACCESS_BACKGROUND_LOCATION) != PackageManager.PERMISSION_GRANTED) 
						{
							return "off";
						} 
						else 
						{
							return "on";
						}
					} 
					else 
					{
						if (ContextCompat.checkSelfPermission(com.fuse.Activity.getRootActivity(), android.Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED 
							&& ContextCompat.checkSelfPermission(com.fuse.Activity.getRootActivity(), android.Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) 
						{
							return "off";
						} 
						else 
						{
							return "on";
						}
					}
				} 
				else 
				{
					return "off";
				}
			}
			else
			{
				//legacy checks
				int mode = android.provider.Settings.Secure.getInt(com.fuse.Activity.getRootActivity().getContentResolver(), android.provider.Settings.Secure.LOCATION_MODE, android.provider.Settings.Secure.LOCATION_MODE_OFF);

				if ((mode != android.provider.Settings.Secure.LOCATION_MODE_OFF)) 
				{
					if (ContextCompat.checkSelfPermission(com.fuse.Activity.getRootActivity(), android.Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED 
							&& ContextCompat.checkSelfPermission(com.fuse.Activity.getRootActivity(), android.Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) 
					{
						return "off";
					} 
					else 
					{
						return "on";
					}
				} 
				else 
				{
					return "off";
				}
			}
		@}
		
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
			if (!IsLocationEnabled())
			{
				RequestPermissions();
				return null;
			}

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
				var minTime = ZonedDateTime.Now.WithZone(DateTimeZone.Utc).Minus(Duration.FromHours(1)).ToInstant();
				return ChooseBestLocation(locations, 100, minTime);
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

			if (bestResult == null) {
				bestAccuracy = minDistance;

				foreach(var location in locations)
				{
					if (location.Accuracy < bestAccuracy) {
						bestResult = location;
						bestAccuracy = location.Accuracy;
					}
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

		[Foreign(Language.Java)]
		static void StartForegroundService()
		@{
			Intent intent = new Intent(com.fuse.Activity.getRootActivity(), BackgroundService.class);
			intent.setAction(BackgroundService.ACTION_START_FOREGROUND_SERVICE);
			ContextCompat.startForegroundService(com.fuse.Activity.getRootActivity(), intent);
		@}

		[Foreign(Language.Java)]
		static void StopForegroundService()
		@{
			Intent intent = new Intent(com.fuse.Activity.getRootActivity(), BackgroundService.class);
			intent.setAction(BackgroundService.ACTION_STOP_FOREGROUND_SERVICE);
			ContextCompat.startForegroundService(com.fuse.Activity.getRootActivity(), intent);
		@}

		public void StartListening(Action<Location> onLocationChanged, Action<Uno.Exception> onLocationError, int minimumReportInterval, double desiredAccuracyInMeters)
		{

			startListening_onLocationChanged = onLocationChanged;
			startListening_minimumReportInterval = minimumReportInterval;
			startListening_desiredAccuracyInMeters = desiredAccuracyInMeters;

			if (!IsLocationEnabled()) {

				RequestStartListeningPermissions();

			} else {
				startListening();
			}


		}

		void RequestStartListeningPermissions()
		{
			int permissionState = checkPermissions();

			switch (permissionState) {
				case 3:	
					var permissions = new PlatformPermission[] 
					{
						Permissions.Android.INTERNET,
						Permissions.Android.ACCESS_COARSE_LOCATION,
						Permissions.Android.ACCESS_FINE_LOCATION
					};
					Permissions.Request(permissions).Then(OnStartListeningPermissionsResult, OnStartListeningPermissionsError);
					break;
				case 2: 
					var permissions = new PlatformPermission[] 
					{
						Permissions.Android.INTERNET,
						Permissions.Android.ACCESS_COARSE_LOCATION,
						Permissions.Android.ACCESS_FINE_LOCATION,
						Permissions.Android.ACCESS_BACKGROUND_LOCATION
					};
					Permissions.Request(permissions).Then(OnStartListeningPermissionsResult, OnStartListeningPermissionsError);
					break;
				case 1: 
					var permissions = new PlatformPermission[] 
					{
						Permissions.Android.ACCESS_BACKGROUND_LOCATION
					};
					Permissions.Request(permissions).Then(OnStartListeningPermissionsResult, OnStartListeningPermissionsError);
					break;
				case 0:
					break;
			}
			
		}

		void startListening() {

			if (_locationManager != null && !_started)
			{
				_onLocationChanged = startListening_onLocationChanged;
				
				if(IsNetworkEnabled(_locationManager))
					RequestNetworkLocationUpdates(_locationManager, startListening_minimumReportInterval, startListening_desiredAccuracyInMeters, _updateListener);
					
				if(IsGPSEnabled(_locationManager))
					RequestGPSLocationUpdates(_locationManager, startListening_minimumReportInterval, startListening_desiredAccuracyInMeters, _updateListener);

				if (@(Project.Android.GeoLocation.BackgroundLocation.Enabled:ToLower) == "true") 
				{
					StartForegroundService();
				}

				_started = true;
			}
		}

		void OnStartListeningPermissionsResult(PlatformPermission[] grantedPermissions)
		{
			startListening();
		}
		
		void OnStartListeningPermissionsError(Exception e)
		{
		}
		
		[Foreign(Language.Java)]
		static void RemoveUpdates(Java.Object manager, Java.Object listener)
		@{
			((LocationManager)manager).removeUpdates((UpdateListener)listener);
		@}
		
		public void StopListening()
		{
			RemoveUpdates(_locationManager, _updateListener);

			if (@(Project.Android.GeoLocation.BackgroundLocation.Enabled:ToLower) == "true") 
			{
				StopForegroundService();
			}

			_started = false;
		}
	}
}
