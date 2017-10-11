using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;

using Fuse;
using Fuse.Controls;
using Fuse.Controls.Native;
using Fuse.Controls.Native.iOS;

namespace Fuse.Controls.Native.iOS
{
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

		public void OnRooted()
		{
			// Do nothing
		}

		public void OnUnrooted()
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