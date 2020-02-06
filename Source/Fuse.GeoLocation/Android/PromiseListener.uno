using Uno.Threading;
using Uno.Compiler.ExportTargetInterop;
using Fuse.GeoLocation.Android;
using Uno.Permissions;
using Uno;

namespace Fuse.GeoLocation
{
	[ForeignInclude(Language.Java, 
		"androidx.core.content.ContextCompat", 
		"android.content.pm.PackageManager", 
		"android.location.LocationManager", 
		"fuse.geolocation.UpdateListener", 
		"android.os.Handler", 
		"android.os.Looper",
		"android.os.Build"
	)]
	extern(Android) internal class PromiseListener
	{
		Promise<Location> _promise;
		static Java.Object _listener;
		static Java.Object _locationManager;
		public PromiseListener(Java.Object locationManagerHandle, double timeout, Promise<Location> promise)
		{
			_locationManager = locationManagerHandle;
			_promise = promise;	
			_listener = CreateListener(OnLocationChanged);
			StartUpdatesWithTimer(_locationManager, _listener, OnTimeout, (int)timeout);
		}
		
		void OnTimeout()
		{
			if(_promise.State != FutureState.Pending) return;
			StopUpdate(_locationManager, _listener);
			_promise.Reject(new Uno.Exception("Location request timed out"));
		}

		void OnLocationChanged(Java.Object location)
		{
			if(_promise.State != FutureState.Pending) return;
			StopUpdate(_locationManager, _listener);
			_promise.Resolve(LocationHelpers.ConvertLocation(location));
		}
		
		[Foreign(Language.Java)]
		static void StopUpdate(Java.Object locationManager, Java.Object listener)
		@{
			Handler h = new Handler(Looper.getMainLooper());
			h.post(new Runnable() {
				@Override 
				public void run() {
					((LocationManager)locationManager).removeUpdates((UpdateListener)listener);
				} 
			});
		@}
		
		[Foreign(Language.Java)]
		static Java.Object CreateListener(Action<Java.Object> onLocationChanged)
		@{
			return new UpdateListener(onLocationChanged);
		@}
		
		[Foreign(Language.Java)]
		static void StartUpdatesWithTimer(Java.Object locationManager, Java.Object listener, Action onTimeout, int timeout)
		@{
			Handler h = new Handler(Looper.getMainLooper());
			h.postDelayed(onTimeout, (long)timeout);				
			h.post(new Runnable(){
				@Override
				public void run() {

					LocationManager lm = (LocationManager) locationManager; 

					if (ContextCompat.checkSelfPermission(com.fuse.Activity.getRootActivity(), android.Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED 
						&& ContextCompat.checkSelfPermission(com.fuse.Activity.getRootActivity(), android.Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED)
					{
						lm.requestSingleUpdate(LocationManager.NETWORK_PROVIDER, (UpdateListener)listener, null);
						lm.requestSingleUpdate(LocationManager.GPS_PROVIDER, (UpdateListener)listener, null);
					}
					else
					{
						@{RequestPermissions():Call()};
					}
				}
			});
		@}

		[Foreign(Language.Java)]
		static int CheckPermissions()
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

		static void RequestPermissions()
		{
			int permissionState = CheckPermissions();

			switch (permissionState)
			{
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
		static void OnPermissionsResult(PlatformPermission[] grantedPermissions)
		{
			GetSingleUpdate(_locationManager, _listener);
		}
		static void OnPermissionsError(Exception e)
		{

		}

		[Foreign(Language.Java)]
		static void GetSingleUpdate(Java.Object locationManager, Java.Object listener)
		@{
			
			LocationManager lm = (LocationManager) locationManager; 
			lm.requestSingleUpdate(LocationManager.NETWORK_PROVIDER, (UpdateListener)listener, null);
			lm.requestSingleUpdate(LocationManager.GPS_PROVIDER, (UpdateListener)listener, null);
		@}
	}
}
