using Uno.Compiler.ExportTargetInterop;
using Fuse.GeoLocation;

namespace Fuse.GeoLocation.Android
{
	[ForeignInclude(Language.Java, "android.location.Location")]
	public extern(Android) class LocationHelpers
	{
		[Foreign(Language.Java)]
		public static double GetAltitude(this Java.Object handle)
		@{
			Location l = (Location)handle;
			return l.getAltitude();
		@}

		[Foreign(Language.Java)]
		public static double GetLatitude(this Java.Object handle)
		@{
			Location l = (Location)handle;
			return l.getLatitude();
		@}

		[Foreign(Language.Java)]
		public static double GetLongitude(this Java.Object handle)
		@{
			Location l = (Location)handle;
			return l.getLongitude();
		@}

		[Foreign(Language.Java)]
		public static double GetSpeed(this Java.Object handle)
		@{
			Location l = (Location)handle;
			return l.getSpeed();
		@}

		[Foreign(Language.Java)]
		public static int GetTime(this Java.Object handle)
		@{
			Location l = (Location)handle;
			return (int)l.getTime();
		@}

		[Foreign(Language.Java)]
		public static float GetAccuracy(this Java.Object handle)
		@{
			Location l = (Location)handle;
			return l.getAccuracy();
		@}

		public static Location ConvertLocation(Java.Object loc)
		{
			var instant = Uno.Time.Instant.FromMillisecondsSinceUnixEpoch(LocationHelpers.GetTime(loc));
			var dateTime = new Uno.Time.LocalDateTime(instant, Uno.Time.CalendarSystem.Iso);

			return new Location(
							new GeoCoordinates(LocationHelpers.GetLatitude(loc),
							LocationHelpers.GetLongitude(loc)),
							LocationHelpers.GetAccuracy(loc),
							LocationHelpers.GetAltitude(loc),
							LocationHelpers.GetSpeed(loc),
							dateTime);
		}
	}
}
