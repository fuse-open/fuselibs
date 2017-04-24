using Uno.Time;

namespace Fuse.GeoLocation
{
	public class GeoCoordinates
	{
	    double _lat;
	    double _long;
	    
	    public double Latitude { get { return _lat; } }
	    public double Longitude { get { return _long; } }

	    public GeoCoordinates(double latitude, double longitude)
	    {
	        _lat = latitude;
	        _long = longitude;
	    }

	    public override string ToString()
	    {
	    	return Latitude + " - " + Longitude;
	    }
	}
}
