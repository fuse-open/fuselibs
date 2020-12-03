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
			Style = _host.Style;

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

		public DatePickerStyle Style
		{
			get
			{
				var style = GetDatePickerStyle(Handle);
				switch (style)
				{
					case 0:
						return DatePickerStyle.Default;
					case 1:
						return DatePickerStyle.Compact;
					case 2:
						return DatePickerStyle.Inline;
					case 3:
						return DatePickerStyle.Wheels;
					default:
						return DatePickerStyle.Default;
				}
			}
			set
			{
				// hack to make rendering native datepicker on compact mode correctly
				if (value == DatePickerStyle.Default || value == DatePickerStyle.Compact)
					_host.Height = new Size(30, Unit.Points);
				else
					_host.Height = new Size(100, Unit.Percent);

				SetDatePickerStyle(Handle, value);
			}
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

		[Foreign(Language.ObjC)]
		int GetDatePickerStyle(ObjC.Object datePickerHandle)
		@{
			#if defined(__IPHONE_13_4) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_4
			UIDatePicker *dp = (UIDatePicker *)datePickerHandle;
			UIDatePickerStyle style = dp.datePickerStyle;
			switch(style)
			{
				case UIDatePickerStyleAutomatic:
					return 0;
				case UIDatePickerStyleCompact:
					return 1;
				case UIDatePickerStyleInline:
					return 2;
				case UIDatePickerStyleWheels:
					return 3;
			}
			#endif
			return 0;
		@}

		[Foreign(Language.ObjC)]
		void SetDatePickerStyle(ObjC.Object datePickerHandle, int style)
		@{
			#if defined(__IPHONE_13_4) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_4
			UIDatePicker *dp = (UIDatePicker *)datePickerHandle;
			UIDatePickerStyle datePickerStyle = UIDatePickerStyleAutomatic;
			switch (style)
			{
				case 0:
					datePickerStyle = UIDatePickerStyleAutomatic;
					break;
				case 1:
					datePickerStyle = UIDatePickerStyleCompact;
					break;
				case 2:
					datePickerStyle = UIDatePickerStyleInline;
					break;
				case 3:
					datePickerStyle = UIDatePickerStyleWheels;
					break;
			}
			[dp setPreferredDatePickerStyle:datePickerStyle];
			#endif
		@}

	}

}
