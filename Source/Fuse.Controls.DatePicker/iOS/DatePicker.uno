using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;

using Fuse;
using Fuse.Controls;
using Fuse.Controls.Native;
using Fuse.Controls.Native.iOS;

namespace Fuse.Controls.Native.iOS
{
	extern(iOS) static class DateTimeConverterHelpers
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

			NSDateComponents *components = [utcCalendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date];

			NSDateComponents *utcComponents = [[NSDateComponents alloc] init];
			[utcComponents setYear:[components year]];
			[utcComponents setMonth:[components month]];
			[utcComponents setDay:[components day]];

			return [utcCalendar dateFromComponents:utcComponents];
		@}
	}

	extern(!iOS) class DatePickerView
	{
		[UXConstructor]
		public DatePickerView([UXParameter("Host")]IDatePickerHost host) { }
	}

	[Require("Source.Include", "UIKit/UIKit.h")]
	extern(iOS) class DatePickerView : LeafView, IDatePickerView
	{
		IDatePickerHost _host;
		IDisposable _valueChangedEvent;

		[UXConstructor]
		public DatePickerView([UXParameter("Host")]IDatePickerHost host) : base(Create())
		{
			_host = host;
			_valueChangedEvent = UIControlEvent.AddValueChangedCallback(Handle, OnValueChanged);
		}

		public override void Dispose()
		{
			base.Dispose();
			_valueChangedEvent.Dispose();
			_valueChangedEvent = null;
			_host = null;
		}

		void OnValueChanged(ObjC.Object sender, ObjC.Object args)
		{
			_host.OnValueChanged();
		}

		public DateTime Value
		{
			get { return DateTimeConverterHelpers.ConvertNSDateToDateTime(DateTimeConverterHelpers.ReconstructUtcDate(GetDate(Handle))); }
			set { SetDate(Handle, DateTimeConverterHelpers.ReconstructUtcDate(DateTimeConverterHelpers.ConvertDateTimeToNSDate(value))); }
		}

		public DateTime MinValue
		{
			get { return DateTimeConverterHelpers.ConvertNSDateToDateTime(DateTimeConverterHelpers.ReconstructUtcDate(GetMinValue(Handle))); }
			set { SetMinValue(Handle, DateTimeConverterHelpers.ReconstructUtcDate(DateTimeConverterHelpers.ConvertDateTimeToNSDate(value))); }
		}

		public DateTime MaxValue
		{
			get { return DateTimeConverterHelpers.ConvertNSDateToDateTime(DateTimeConverterHelpers.ReconstructUtcDate(GetMaxValue(Handle))); }
			set { SetMaxValue(Handle, DateTimeConverterHelpers.ReconstructUtcDate(DateTimeConverterHelpers.ConvertDateTimeToNSDate(value))); }
		}

		public void PollViewValue()
		{
			// Do nothing
		}

		[Foreign(Language.ObjC)]
		static ObjC.Object Create()
		@{
			UIDatePicker *dp = [[UIDatePicker alloc] init];

			[dp setDatePickerMode:UIDatePickerModeDate];

			// Make sure the date picker interprets date values in UTC
			[dp setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

			return dp;
		@}

		[Foreign(Language.ObjC)]
		void SetDate(ObjC.Object datePickerHandle, ObjC.Object date)
		@{
			UIDatePicker *dp = (UIDatePicker *)datePickerHandle;

			[dp setDate:date animated:true];
		@}

		[Foreign(Language.ObjC)]
		ObjC.Object GetDate(ObjC.Object datePickerHandle)
		@{
			UIDatePicker *dp = (UIDatePicker *)datePickerHandle;

			return [dp date];
		@}

		[Foreign(Language.ObjC)]
		void SetMinValue(ObjC.Object datePickerHandle, ObjC.Object date)
		@{
			UIDatePicker *dp = (UIDatePicker *)datePickerHandle;

			[dp setMinimumDate:date];
		@}

		[Foreign(Language.ObjC)]
		ObjC.Object GetMinValue(ObjC.Object datePickerHandle)
		@{
			UIDatePicker *dp = (UIDatePicker *)datePickerHandle;

			return [dp minimumDate];
		@}

		[Foreign(Language.ObjC)]
		void SetMaxValue(ObjC.Object datePickerHandle, ObjC.Object date)
		@{
			UIDatePicker *dp = (UIDatePicker *)datePickerHandle;

			[dp setMaximumDate:date];
		@}

		[Foreign(Language.ObjC)]
		ObjC.Object GetMaxValue(ObjC.Object datePickerHandle)
		@{
			UIDatePicker *dp = (UIDatePicker *)datePickerHandle;

			return [dp maximumDate];
		@}
	}

}