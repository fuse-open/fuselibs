using Uno;
using Uno.Time;

namespace Experimental.Http.Internal
{
	static class DateUtil
	{
		public static int TimestampNow
		{
			get
			{
				//rough timestamp
				var d = ZonedDateTime.Now;
				var mon = (d.Year - 2000) * 12 + d.Month;
				var day = (mon * 31) + d.Day;
				var hour = (day * 24) + d.Hour;
				var min = (hour * 60) + d.Minute;
				var sec = (min * 60) + d.Second;
				return sec;
			}
		}
	}
}
