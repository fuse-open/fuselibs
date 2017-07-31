using Uno;
using Uno.Time;

namespace Fuse.Reactive
{
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

			var jsTicks = (long)date.Ticks;
			const long dotNetTicksInJsTick = 10000L;
			var dotNetTicksRelativeToUnixEpoch = jsTicks * dotNetTicksInJsTick;
			const long unixEpochInDotNetTicks = 621355968000000000L;
			var dotNetTicks = dotNetTicksRelativeToUnixEpoch + unixEpochInDotNetTicks;

			return new DateTime(dotNetTicks, DateTimeKind.Utc);
		}

		static DateTimeConverter()
		{
			Marshal.AddConverter(new DateTimeConverter());
		}
	}

	class Date
	{
		readonly Scripting.Object _jsDate;

		public double Ticks { get { return (double)_jsDate.CallMethod("getTime"); } }

		public Date(Scripting.Object jsDate)
		{
			_jsDate = jsDate;

			// :(((((
			var dasdfasdfasdf2 = new DateTimeConverter();
		}
	}
}
