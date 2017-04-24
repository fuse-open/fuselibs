using Uno.Time;

namespace Fuse.GeoLocation
{
	public class Location
	{
		GeoCoordinates _coordinates;
		LocalDateTime _dateTime;
		double _altitude;
		double _accuracy;
		double _speed;

		public GeoCoordinates Coordinates { get { return _coordinates; } }
		public LocalDateTime DateTime { get { return _dateTime; }}

		/*
		 * Horizontal accuracy in meters
		 */
		public double Accuracy { get { return _accuracy; } }

		public double Altitude { get { return _altitude; } }

		public double Speed { get { return _speed; } }

		public Location(GeoCoordinates coordinates, double accuracy, double altitude, double speed, LocalDateTime dateTime)
		{
			_coordinates = coordinates;
			_accuracy = accuracy;
			_dateTime = dateTime;
			_altitude = altitude;
			_speed = speed;
		}

		public override string ToString()
		{
			return Coordinates + " " + Accuracy + " (" + DateTime.Month + "/" + DateTime.Day + " " + DateTime.Hour + ":" + DateTime.Minute + ")";
		}
	}
}
