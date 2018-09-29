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
		public DatePickerView([UXParameter("Host")]DatePicker host) { }
	}

	[Require("Source.Include", "UIKit/UIKit.h")]
	extern(iOS) class DatePickerView : LeafView, IDatePickerView
	{
		DatePicker _host;
		IDisposable _valueChangedEvent;

		[UXConstructor]
		public DatePickerView([UXParameter("Host")]DatePicker host) : base(Create())
		{
			_host = host;

			// The native control might reject values outside of the min/max range, so make sure we set min/max first
			MinValue = _host.MinValue;
			MaxValue = _host.MaxValue;
			Value = _host.Value;

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
			_host.OnNativeViewValueChanged(Value);
		}

		public DateTime Value
		{
			get { return DateTimeConverterHelpers.ConvertNSDateToDateTime(DateTimeConverterHelpers.ReconstructUtcDate(GetDate(Handle))); }
			set { SetDate(Handle, DateTimeConverterHelpers.ReconstructUtcDate(DateTimeConverterHelpers.ConvertDateTimeToNSDate(value))); }
		}

		public DateTime MinValue
		{
			set { SetMinValue(Handle, DateTimeConverterHelpers.ReconstructUtcDate(DateTimeConverterHelpers.ConvertDateTimeToNSDate(value))); }
		}

		public DateTime MaxValue
		{
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
		void SetMaxValue(ObjC.Object datePickerHandle, ObjC.Object date)
		@{
			UIDatePicker *dp = (UIDatePicker *)datePickerHandle;

			[dp setMaximumDate:date];
		@}
	}

}
