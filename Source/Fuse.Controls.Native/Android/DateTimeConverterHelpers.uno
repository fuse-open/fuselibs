using Uno;

namespace Fuse.Controls.Native.Android
{
	extern(Android) internal static class DateTimeConverterHelpers
	{
		const long DotNetTicksInMs = 10000L;
		const long UnixEpochInDotNetTicks = 621355968000000000L;

		public static DateTime ConvertMsSince1970InUtcToDateTime(long msSince1970InUtc)
		{
			var dotNetTicksRelativeToUnixEpoch = msSince1970InUtc * DotNetTicksInMs;
			var dotNetTicks = dotNetTicksRelativeToUnixEpoch + UnixEpochInDotNetTicks;

			return new DateTime(dotNetTicks, DateTimeKind.Utc);
		}

		public static long ConvertDateTimeToMsSince1970InUtc(DateTime dt)
		{
			dt = dt.ToUniversalTime();

			var dotNetTicks = dt.Ticks;
			var dotNetTicksRelativeToUnixEpoch = dotNetTicks - UnixEpochInDotNetTicks;
			var msSince1970InUtc = dotNetTicksRelativeToUnixEpoch / DotNetTicksInMs;

			return msSince1970InUtc;
		}
	}
}
