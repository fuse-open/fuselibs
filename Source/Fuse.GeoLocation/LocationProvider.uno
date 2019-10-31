using Uno;
using Uno.Collections;
using Uno.Threading;

namespace Fuse.GeoLocation
{
	interface ILocationTracker
	{
		Location GetLastKnownPosition();

		void GetLocation(Promise<Location> promise, double timeout);

		void StartListening(Action<Location> onLocationChanged, Action<Exception> onLocationError, int minimumReportInterval, double desiredAccuracyInMeters);
		
		void StopListening();

		bool IsLocationEnabled();
		string GetAuthorizationStatus();

		void RequestAuthorization(GeoLocationAuthorizationType type);
		
		void Init(Action onReady);
	}
	
	public enum GeoLocationAuthorizationType
	{
		Never = 0,
		WhenInUse,
		Always
	}

	public partial class LocationTracker
	{
		static ILocationTracker _locationTracker;
		IList<BufferedCall> _bufferedCalls;
		public LocationTracker()
		{
			_bufferedCalls = new List<BufferedCall>();
			AuthorizationType = GeoLocationAuthorizationType.WhenInUse;
			UpdateManager.Dispatcher.Invoke(Init);
		}

		void Init()
		{
			if(_locationTracker != null) return;
			
			if defined(Android)
				_locationTracker = new AndroidLocationProvider();
			else if defined(iOS)
				_locationTracker = new IOSLocationProvider();
			else
				_locationTracker = new SpoofLocationProvider();
				
			_locationTracker.Init(FlushBufferedCalls);
		}
		
		void FlushBufferedCalls()
		{
			foreach(var call in _bufferedCalls)
				call.Apply(_locationTracker);
			_bufferedCalls = null;
			_isReady = true;
		}
		
		public event Action<Location> LocationChanged;
		
		public event Action<string> LocationError;
		
		bool _isReady;

		Location _lastLocation;

		public GeoLocationAuthorizationType AuthorizationType { get; set; }

		public Location Location
		{
			get
			{
				if(_lastLocation == null && _isReady)
				{
					_locationTracker.RequestAuthorization(AuthorizationType);
					_lastLocation = _locationTracker.GetLastKnownPosition();
				}

				return _lastLocation;
			}
		}

		public bool IsLocationEnabled()
		{
			return _locationTracker.IsLocationEnabled();
		}

		public string GetAuthorizationStatus()
		{
			return _locationTracker.GetAuthorizationStatus();
		}

		void OnLocationChanged(Location newLocation)
		{
			if(LocationChanged != null)
				LocationChanged(newLocation);
		}

		void OnLocationError(Exception error)
		{
			if(LocationError != null)
				LocationError(error.Message);
		}

		public void StartListening(int minimumReportInterval = 500, double desiredAccuracyInMeters = 10)
		{
			if (!_isReady)
			{
				_bufferedCalls.Add(new StartListeningCall(OnLocationChanged, OnLocationError,minimumReportInterval, desiredAccuracyInMeters));
				return;
			}

			_locationTracker.RequestAuthorization(AuthorizationType);
			_locationTracker.StartListening(OnLocationChanged, OnLocationError, minimumReportInterval, desiredAccuracyInMeters);
		}
		
		public void StopListening()
		{
			if (!_isReady)
			{
				_bufferedCalls.Add(new StopListeningCall());
				return;
			}

			_locationTracker.StopListening();
		}

		public Future<Location> GetLocationAsync(double timeout = 20000)
		{
			var promise = new Promise<Location>();

			//TODO: Try to get last known location and run an algorithm to see if it's acceptable
			try
			{
				if(!_isReady)
				{
					_bufferedCalls.Add(new GetLocationCall(promise, timeout));
					return promise;
				}
				_locationTracker.RequestAuthorization(AuthorizationType);
				_locationTracker.GetLocation(promise, timeout);
			}
			catch (Exception e)
			{
				promise.Reject(e);
			}

			return promise;
		}
	}
}
