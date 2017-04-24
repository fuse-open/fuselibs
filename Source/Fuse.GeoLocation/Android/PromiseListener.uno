using Uno.Threading;
using Uno.Compiler.ExportTargetInterop;
using Fuse.GeoLocation.Android;
using Uno;
namespace Fuse.GeoLocation
{
	[ForeignInclude(Language.Java, "android.location.LocationManager", "fuse.geolocation.UpdateListener", "android.os.Handler", "android.os.Looper")]
	extern(Android) internal class PromiseListener
	{
		Promise<Location> _promise;
		Java.Object _listener;
		Java.Object _locationManager;
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
					lm.requestSingleUpdate(LocationManager.NETWORK_PROVIDER, (UpdateListener)listener, null);
					lm.requestSingleUpdate(LocationManager.GPS_PROVIDER, (UpdateListener)listener, null);
				}
			});
		@}
	}
}
