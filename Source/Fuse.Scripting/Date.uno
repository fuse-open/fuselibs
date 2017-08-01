using Uno;
using Uno.Time;

namespace Fuse.Scripting
{
	static class DateTimeConverterHelpers
	{
		const long dotNetTicksInJsTick = 10000L;
		const long unixEpochInDotNetTicks = 621355968000000000L;

		public static DateTime ConvertDateToDateTime(Date date)
		{
			var jsTicks = (long)date.Ticks;
			var dotNetTicksRelativeToUnixEpoch = jsTicks * dotNetTicksInJsTick;
			var dotNetTicks = dotNetTicksRelativeToUnixEpoch + unixEpochInDotNetTicks;

			return new DateTime(dotNetTicks, DateTimeKind.Utc);
		}

		public static object ConvertDateTimeToJSDate(DateTime dt, Context context)
		{
			var dotNetTicks = dt.Ticks;
			var dotNetTicksRelativeToUnixEpoch = dotNetTicks - unixEpochInDotNetTicks;
			var jsTicks = dotNetTicksRelativeToUnixEpoch / dotNetTicksInJsTick;

			return context.DateCtor.Call((double)jsTicks);
		}
	}

	class DateTimeConverter: Marshal.IConverter
	{
		public bool CanConvert(Type t)
		{
			return t == typeof(DateTime) || t.IsSubclassOf(typeof(DateTime));
		}
		public object TryConvert(Type t, object o)
		{
			if (!CanConvert(t))
				return null;

			var date = o as Date;
			if (date == null)
				return null;

			return DateTimeConverterHelpers.ConvertDateToDateTime(date);
		}

		static DateTimeConverter()
		{
			Marshal.AddConverter(new DateTimeConverter());
		}
	}

	class Date
	{
		readonly Object _jsDate;

		public double Ticks { get { return (double)_jsDate.CallMethod("getTime"); } }

		public Date(Object jsDate)
		{
			_jsDate = jsDate;

			// Dummy converter to ensure the DateTimeConverter is referenced so
			//  that we can ensure its static ctor is invoked so it can be used
			//  by the marshal
			var dummyConverter = new DateTimeConverter();
		}
	}
}
