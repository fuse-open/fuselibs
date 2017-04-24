using Uno.Threading;
using Uno;

namespace Fuse.GeoLocation
{
	public partial class LocationTracker
	{
		interface BufferedCall {
			void Apply(ILocationTracker tracker);
		}

		class StartListeningCall : BufferedCall
		{
			readonly int minimumReportInterval;
			readonly double desiredAccuracyInMeters;
			readonly Action<Location> onLocationChanged;
			readonly Action<Exception> onLocationError;
			public StartListeningCall(Action<Location> onLocationChanged, Action<Exception> onLocationError, int minimumReportInterval, double desiredAccuracyInMeters)
			{
				this.minimumReportInterval = minimumReportInterval;
				this.desiredAccuracyInMeters = desiredAccuracyInMeters;
				this.onLocationError = onLocationError;
				this.onLocationChanged = onLocationChanged;
			}
			public void Apply(ILocationTracker tracker)
			{
				tracker.StartListening(onLocationChanged, onLocationError, minimumReportInterval, desiredAccuracyInMeters);
			}
		}
		
		class StopListeningCall : BufferedCall 
		{
			public StopListeningCall()
			{
			}
			public void Apply(ILocationTracker tracker)
			{
				tracker.StopListening();
			}
		}
		
		class GetLocationCall : BufferedCall {
			readonly Promise<Location> promise;
			readonly double timeout;
			public GetLocationCall(Promise<Location> promise, double timeout)
			{
				this.promise = promise;
				this.timeout = timeout;
			}
			public void Apply(ILocationTracker tracker)
			{
				tracker.GetLocation(promise, timeout);
			}
		}
	}
}
