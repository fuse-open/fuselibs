using Uno;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls.Native.iOS
{
	extern(iOS) internal static class DateTimeConverterHelpers
	{
		const long DotNetTicksInSecond = 10000000L;
		const long UnixEpochInDotNetTicks = 621355968000000000L;

		public static DateTime ConvertNSDateToDateTime(ObjC.Object date)
		{
			var secondsSince1970InUtc = (long)NSDateToSecondsSince1970InUtc(date);

			var dotNetTicksRelativeToUnixEpoch = (long)secondsSince1970InUtc * DotNetTicksInSecond;
			var dotNetTicks = dotNetTicksRelativeToUnixEpoch + UnixEpochInDotNetTicks;

			return new DateTime(dotNetTicks, DateTimeKind.Utc);
		}

		public static ObjC.Object ConvertDateTimeToNSDate(DateTime dt)
		{
			dt = dt.ToUniversalTime();

			var dotNetTicks = dt.Ticks;
			var dotNetTicksRelativeToUnixEpoch = dotNetTicks - UnixEpochInDotNetTicks;
			var secondsSince1970InUtc = dotNetTicksRelativeToUnixEpoch / DotNetTicksInSecond;

			return SecondsSince1970InUtcToNSDate((double)secondsSince1970InUtc);
		}

		[Foreign(Language.ObjC)]
		public static double NSDateToSecondsSince1970InUtc(ObjC.Object date)
		@{
			return [date timeIntervalSince1970];
		@}

		[Foreign(Language.ObjC)]
		public static ObjC.Object SecondsSince1970InUtcToNSDate(double secondsSince1970InUtc)
		@{
			return [NSDate dateWithTimeIntervalSince1970:secondsSince1970InUtc];
		@}

		[Foreign(Language.ObjC)]
		public static ObjC.Object ReconstructUtcDate(ObjC.Object date)
		@{
			if (!date)
				return [NSDate dateWithTimeIntervalSince1970:0];

			// Reconstruct the same date in UTC without time components
			NSCalendar *utcCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
			[utcCalendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

			NSDateComponents *components = [utcCalendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:date];

			NSDateComponents *utcComponents = [[NSDateComponents alloc] init];
			[utcComponents setYear:[components year]];
			[utcComponents setMonth:[components month]];
			[utcComponents setDay:[components day]];

			return [utcCalendar dateFromComponents:utcComponents];
		@}

		[Foreign(Language.ObjC)]
		public static ObjC.Object ReconstructUtcTime(ObjC.Object date)
		@{
			if (!date)
				return [NSDate dateWithTimeIntervalSince1970:0];

			// Reconstruct the same date in UTC without date components
			NSCalendar *utcCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
			[utcCalendar setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

			NSDateComponents *components = [utcCalendar components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:date];

			NSDateComponents *utcComponents = [[NSDateComponents alloc] init];
			[utcComponents setYear:1970];
			[utcComponents setMonth:1];
			[utcComponents setDay:1];
			[utcComponents setHour:[components hour]];
			[utcComponents setMinute:[components minute]];

			return [utcCalendar dateFromComponents:utcComponents];
		@}
	}
}