using Uno;
using Uno.Time;

namespace Fuse.Scripting
{
	static class DateTimeConverterHelpers
	{
		const long DotNetTicksInJsTick = 10000L;
		const long UnixEpochInDotNetTicks = 621355968000000000L;

		public static DateTime ConvertDateToDateTime(Scripting.Object date)
		{
			var jsTicks = (long)(double)date.CallMethod("getTime");
			var dotNetTicksRelativeToUnixEpoch = jsTicks * DotNetTicksInJsTick;
			var dotNetTicks = dotNetTicksRelativeToUnixEpoch + UnixEpochInDotNetTicks;

			return new DateTime(dotNetTicks, DateTimeKind.Utc);
		}

		public static object ConvertDateTimeToJSDate(DateTime dt, Context context)
		{
			var dotNetTicks = dt.Ticks;
			var dotNetTicksRelativeToUnixEpoch = dotNetTicks - UnixEpochInDotNetTicks;
			var jsTicks = dotNetTicksRelativeToUnixEpoch / DotNetTicksInJsTick;

			return context.DateCtor.Call((double)jsTicks);
		}
	}
}
