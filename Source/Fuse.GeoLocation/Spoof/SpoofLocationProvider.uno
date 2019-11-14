using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Uno.Threading;
using Uno.Time;
using Uno;

namespace Fuse.GeoLocation
{
	public class SpoofLocationProvider : ILocationTracker
	{
		Location SpoofLocation;
		public SpoofLocationProvider()
		{
			SpoofLocation = new Location(new GeoCoordinates(59.9115546,10.73888), 100, 50, 0.5, ZonedDateTime.Now.LocalDateTime);
		}
		public Location GetLastKnownPosition(){
			return SpoofLocation;
		}

		public void GetLocation(Promise<Location> promise, double timeout)
		{
			promise.Resolve(SpoofLocation);
		}

		public void StartListening(Action<Location> onLocationChanged, Action<Exception> onLocationError, int minimumReportInterval, double desiredAccuracyInMeters)
		{
		}
		
		public void StopListening()
		{	
		}
		
		public bool IsLocationEnabled()
		{	
			return false;
		}
		
		public string GetAuthorizationStatus()
		{	
			return "never";
		}

		public void RequestAuthorization(GeoLocationAuthorizationType type)
		{	
		}
		
		public void Init(Action onReady)
		{
			onReady();
		}
	}
}
