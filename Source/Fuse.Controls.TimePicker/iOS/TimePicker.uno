using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;

using Fuse;
using Fuse.Controls;
using Fuse.Controls.Native;
using Fuse.Controls.Native.iOS;

namespace Fuse.Controls.Native.iOS
{
	extern(!iOS) class TimePickerView
	{
		[UXConstructor]
		public TimePickerView([UXParameter("Host")]TimePicker host) { }
	}

	[Require("Source.Include", "UIKit/UIKit.h")]
	extern(iOS) class TimePickerView : LeafView, ITimePickerView
	{
		TimePicker _host;
		IDisposable _valueChangedEvent;

		[UXConstructor]
		public TimePickerView([UXParameter("Host")]TimePicker host) : base(Create())
		{
			_host = host;

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

		public DateTime Value
		{
			get { return DateTimeConverterHelpers.ConvertNSDateToDateTime(DateTimeConverterHelpers.ReconstructUtcTime(GetTime(Handle))); }
			set { SetTime(Handle, DateTimeConverterHelpers.ReconstructUtcTime(DateTimeConverterHelpers.ConvertDateTimeToNSDate(value))); }
		}

		public TimePickerStyle Style
		{
			get
			{
				var style = GetTimePickerStyle(Handle);
				switch (style)
				{
					case 0:
						return TimePickerStyle.Default;
					case 1:
						return TimePickerStyle.Compact;
					case 2:
						return TimePickerStyle.Inline;
					case 3:
						return TimePickerStyle.Wheels;
					default:
						return TimePickerStyle.Default;
				}
			}
			set
			{
				// hack to make rendering native datepicker on compact mode correctly
				if (value == TimePickerStyle.Default || value == TimePickerStyle.Compact)
					_host.Height = new Size(30, Unit.Points);
				else
					_host.Height = new Size(100, Unit.Percent);

				SetTimePickerStyle(Handle, value);
			}
		}

		// Dummy prop, as the iOS API doesn't provide an explicit API for this.
		public bool Is24HourView
		{
			set {
				// Do nothing
			}
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

			[dp setDatePickerMode:UIDatePickerModeTime];

			// Make sure the time picker interprets date values in UTC
			[dp setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

			return dp;
		@}

		[Foreign(Language.ObjC)]
		void SetTime(ObjC.Object datePickerHandle, ObjC.Object time)
		@{
			UIDatePicker *dp = (UIDatePicker *)datePickerHandle;

			[dp setDate:time animated:true];
		@}

		[Foreign(Language.ObjC)]
		ObjC.Object GetTime(ObjC.Object datePickerHandle)
		@{
			UIDatePicker *dp = (UIDatePicker *)datePickerHandle;

			return [dp date];
		@}

		[Foreign(Language.ObjC)]
		int GetTimePickerStyle(ObjC.Object timePickerHandle)
		@{
			#if defined(__IPHONE_13_4) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_4
			UIDatePicker *dp = (UIDatePicker *)timePickerHandle;
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
		void SetTimePickerStyle(ObjC.Object timePickerHandle, int style)
		@{
			#if defined(__IPHONE_13_4) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_4
			UIDatePicker *dp = (UIDatePicker *)timePickerHandle;
			UIDatePickerStyle datePickerStyle;
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
