using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;

using Fuse;
using Fuse.Controls;
using Fuse.Controls.Native;

namespace Fuse.Controls.Native.Android
{
	extern(!Android) class TimePickerView
	{
		[UXConstructor]
		public TimePickerView([UXParameter("Host")]TimePicker host) { }
	}

	extern(Android) class TimePickerView : LeafView, ITimePickerView
	{
		TimePicker _host;

		[UXConstructor]
		public TimePickerView([UXParameter("Host")]TimePicker host) : base(Create())
		{
			_host = host;

			Value = _host.Value;
			Is24HourView = _host.Is24HourView;

			// onTimeChanged is extremely inconsistent, esp. when using the now-default clock mode, so
			//  let's just skip trying to use it altogether and go for a polling-based approach instead.
			UpdatePollValueCache();
		}

		public override void Dispose()
		{
			base.Dispose();
			_host = null;
		}

		public DateTime Value
		{
			get
			{
				var msSince1970InUtc = GetTimeInMsSince1970InUtc(Handle);
				return DateTimeConverterHelpers.ConvertMsSince1970InUtcToDateTime(msSince1970InUtc);
			}
			set
			{
				SetTime(Handle, DateTimeConverterHelpers.ConvertDateTimeToMsSince1970InUtc(value));
				UpdatePollValueCache();
			}
		}

		DateTime _pollValueCache;

		void UpdatePollValueCache()
		{
			_pollValueCache = Value;
		}

		public void PollViewValue()
		{
			if (Value != _pollValueCache)
			{
				OnValueChanged(Value);
				UpdatePollValueCache();
			}
		}

		public void OnRooted()
		{
			UpdateManager.AddAction(PollViewValue);
		}

		public void OnUnrooted()
		{
			UpdateManager.RemoveAction(PollViewValue);
		}

		void OnValueChanged(DateTime value)
		{
			_host.OnNativeViewValueChanged(value);
		}

		public bool Is24HourView
		{
			set { SetIs24HourView(Handle, value); }
		}

		[Foreign(Language.Java)]
		static Java.Object Create()
		@{
			return new android.widget.TimePicker(com.fuse.Activity.getRootActivity());
		@}

		[Foreign(Language.Java)]
		void SetTime(Java.Object timePickerHandle, long msSince1970InUtc)
		@{
			java.util.Calendar cal = java.util.Calendar.getInstance(java.util.TimeZone.getTimeZone("UTC"), java.util.Locale.getDefault());
			cal.setTimeInMillis(msSince1970InUtc);

			int hour = cal.get(java.util.Calendar.HOUR);
			if (cal.get(java.util.Calendar.AM_PM) == java.util.Calendar.PM)
				hour += 12;
			int minute = cal.get(java.util.Calendar.MINUTE);

			android.widget.TimePicker timePicker = (android.widget.TimePicker)timePickerHandle;

			if (android.os.Build.VERSION.SDK_INT >= 23) {
				timePicker.setHour(hour);
				timePicker.setMinute(minute);
			} else {
				timePicker.setCurrentHour(hour);
				timePicker.setCurrentMinute(minute);
			}
		@}

		[Foreign(Language.Java)]
		long GetTimeInMsSince1970InUtc(Java.Object timePickerHandle)
		@{
			android.widget.TimePicker timePicker = (android.widget.TimePicker)timePickerHandle;

			int hour, minute;

			if (android.os.Build.VERSION.SDK_INT >= 23) {
				hour = timePicker.getHour();
				minute = timePicker.getMinute();
			} else {
				hour = timePicker.getCurrentHour();
				minute = timePicker.getCurrentMinute();
			}

			// Remove date offsets so we only express the time in UTC
			java.util.Calendar cal = java.util.Calendar.getInstance(java.util.TimeZone.getTimeZone("UTC"), java.util.Locale.getDefault());

			cal.set(java.util.Calendar.YEAR, 1970);
			cal.set(java.util.Calendar.MONTH, 0); // Android month starts at 0
			cal.set(java.util.Calendar.DAY_OF_MONTH, 1);

			cal.set(java.util.Calendar.AM_PM, java.util.Calendar.AM);
			cal.set(java.util.Calendar.HOUR, hour);
			cal.set(java.util.Calendar.MINUTE, minute);
			cal.set(java.util.Calendar.SECOND, 0);
			cal.set(java.util.Calendar.MILLISECOND, 0);

			return cal.getTimeInMillis();
		@}

		[Foreign(Language.Java)]
		void SetIs24HourView(Java.Object timePickerHandle, bool value)
		@{
			android.widget.TimePicker timePicker = (android.widget.TimePicker)timePickerHandle;

			timePicker.setIs24HourView(value);
		@}
	}
}
