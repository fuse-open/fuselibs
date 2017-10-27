using Fuse.Scripting;
using Uno;
using Uno.Collections;
using Uno.Text;
using Uno.Threading;
using Uno.IO;
using Uno.UX;

namespace Fuse.Scripting.JavaScript
{
	static class DateTimeConverterHelpers
	{
		const long DotNetTicksInJsTick = 10000L;
		const long UnixEpochInDotNetTicks = 621355968000000000L;

		public static DateTime ConvertDateToDateTime(Scripting.Context context, Scripting.Object date)
		{
			var jsTicks = (long)(double)context.Wrap(date.CallMethod(context, "getTime"));
			var dotNetTicksRelativeToUnixEpoch = jsTicks * DotNetTicksInJsTick;
			var dotNetTicks = dotNetTicksRelativeToUnixEpoch + UnixEpochInDotNetTicks;

			return new DateTime(dotNetTicks, DateTimeKind.Utc);
		}

		public static object ConvertDateTimeToJSDate(Scripting.Context context, DateTime dt, Scripting.Function dateCtor)
		{
			// TODO: This assumes dt's `Kind` is set to `Utc`. The `Ticks` value may have to be adjusted if `Kind` is `Local` or `Unspecified`.
			//  Currently we don't support other `Kind`'s than `Utc`, but when we do, this code should be updated accordingly.
			//  Something like: `if (dt.Kind != DateTimeKind.Utc) { dt = dt.ToUniversalTime(); }`
			var dotNetTicks = dt.Ticks;
			var dotNetTicksRelativeToUnixEpoch = dotNetTicks - UnixEpochInDotNetTicks;
			var jsTicks = dotNetTicksRelativeToUnixEpoch / DotNetTicksInJsTick;

			return dateCtor.Call(context, (double)jsTicks);
		}
	}
}
