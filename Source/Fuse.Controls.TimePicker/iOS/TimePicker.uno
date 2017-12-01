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
	}

}
