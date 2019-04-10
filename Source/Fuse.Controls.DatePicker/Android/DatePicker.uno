using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;

using Fuse;
using Fuse.Controls;
using Fuse.Controls.Native;

namespace Fuse.Controls.Native.Android
{
	extern(!Android) class DatePickerView
	{
		[UXConstructor]
		public DatePickerView([UXParameter("Host")]DatePicker host) { }
	}

	extern(Android) class DatePickerView : LeafView, IDatePickerView
	{
		DatePicker _host;

		[UXConstructor]
		public DatePickerView([UXParameter("Host")]DatePicker host) : base(Create())
		{
			_host = host;

			Init(Handle);

			// The native control might reject values outside of the min/max range, so make sure we set min/max first
			MinValue = _host.MinValue;
			MaxValue = _host.MaxValue;
			Value = _host.Value;

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
				var msSince1970InUtc = GetDateInMsSince1970InUtc(Handle);
				return DateTimeConverterHelpers.ConvertMsSince1970InUtcToDateTime(msSince1970InUtc);
			}
			set
			{
				SetDate(Handle, DateTimeConverterHelpers.ConvertDateTimeToMsSince1970InUtc(value));
				UpdatePollValueCache();
			}
		}

		DateTime _pollValueCache;

		void UpdatePollValueCache()
		{
			_pollValueCache = Value;
		}

		void PollViewValue()
		{
			if (Value != _pollValueCache)
			{
				OnValueChanged(Value);
				UpdatePollValueCache();
			}
		}

		// On older versions of Android, layout changes can cause the calendar part of the DatePicker's
		//  view to scroll to a bogus month, which both makes the view look like it has the wrong value,
		//  and also makes it hard to pick a relevant value in many cases. To get around this, we need
		//  to somehow get the control to scroll to show the currently set value whenever layout changes.
		//  To achieve this, we'll reset a counter to zero on layout change, count that up a couple times
		//  in order to wait at least 1 frame (we need more than just one iteration to avoid potential
		//  update manager ordering issues). Then, we'll grab the picker's current value and write it
		//  back, tricking the picker to invalidate and scroll where we want it. The downside of this
		//  approach is that _any_ change in layout that causes this view to change size will scroll
		//  the picker view to the currently selected value, but this is a decent tradeoff.
		int writebackFrameCounter = 0;

		internal protected override void OnSizeChanged()
		{
			if (GetApiLevel() >= 24)
				return;

			writebackFrameCounter = 0;
		}

		void UpdateWriteback()
		{
			if (GetApiLevel() >= 24)
				return;

			if (writebackFrameCounter < 2)
			{
				writebackFrameCounter++;
				if (writebackFrameCounter == 2)
				{
					var v = DateTimeConverterHelpers.ConvertDateTimeToMsSince1970InUtc(Value);
					SetDate(Handle, v - 1); // Write temp value, as the picker won't scroll unless the value actually changes
					SetDate(Handle, v);
				}
			}
		}

		public void Update()
		{
			PollViewValue();
			UpdateWriteback();
		}

		public void OnRooted()
		{
			UpdateManager.AddAction(Update);
		}

		public void OnUnrooted()
		{
			UpdateManager.RemoveAction(Update);
		}

		void OnValueChanged(DateTime value)
		{
			_host.OnNativeViewValueChanged(value);
		}

		public DateTime MinValue
		{
			set { SetMinValue(Handle, DateTimeConverterHelpers.ConvertDateTimeToMsSince1970InUtc(value)); }
		}

		public DateTime MaxValue
		{
			set { SetMaxValue(Handle, DateTimeConverterHelpers.ConvertDateTimeToMsSince1970InUtc(value)); }
		}

		[Foreign(Language.Java)]
		static int GetApiLevel()
		@{
			return android.os.Build.VERSION.SDK_INT;
		@}

		[Foreign(Language.Java)]
		static Java.Object Create()
		@{
			return new android.widget.DatePicker(com.fuse.Activity.getRootActivity());
		@}

		[Foreign(Language.Java)]
		void Init(Java.Object datePickerHandle)
		@{
			android.widget.DatePicker datePicker = (android.widget.DatePicker)datePickerHandle;

			// Use local calendar to get default year/month/day
			java.util.Calendar cal = java.util.Calendar.getInstance();

			int y = cal.get(java.util.Calendar.YEAR);
			int m = cal.get(java.util.Calendar.MONTH);
			int d = cal.get(java.util.Calendar.DAY_OF_MONTH);

			// onDateChangedListener is extremely inconsistent, esp. when using the now-default material theme,
			//  so let's just skip trying to use it altogether and go for a polling-based approach instead.
			datePicker.init(y, m, d, null);
		@}

		[Foreign(Language.Java)]
		void SetDate(Java.Object datePickerHandle, long msSince1970InUtc)
		@{
			java.util.Calendar cal = java.util.Calendar.getInstance(java.util.TimeZone.getTimeZone("UTC"), java.util.Locale.getDefault());
			cal.setTimeInMillis(msSince1970InUtc);

			int y = cal.get(java.util.Calendar.YEAR);
			int m = cal.get(java.util.Calendar.MONTH);
			int d = cal.get(java.util.Calendar.DAY_OF_MONTH);

			android.widget.DatePicker datePicker = (android.widget.DatePicker)datePickerHandle;
			datePicker.updateDate(y, m, d);
		@}

		[Foreign(Language.Java)]
		long GetDateInMsSince1970InUtc(Java.Object datePickerHandle)
		@{
			android.widget.DatePicker datePicker = (android.widget.DatePicker)datePickerHandle;

			// Remove time/zone/dst offsets and set time to midnight so we only express the date in UTC
			java.util.Calendar cal = java.util.Calendar.getInstance(java.util.TimeZone.getTimeZone("UTC"), java.util.Locale.getDefault());

			cal.set(java.util.Calendar.YEAR, datePicker.getYear());
			cal.set(java.util.Calendar.MONTH, datePicker.getMonth());
			cal.set(java.util.Calendar.DAY_OF_MONTH, datePicker.getDayOfMonth());

			cal.set(java.util.Calendar.AM_PM, java.util.Calendar.AM);
			cal.set(java.util.Calendar.HOUR, 0);
			cal.set(java.util.Calendar.MINUTE, 0);
			cal.set(java.util.Calendar.SECOND, 0);
			cal.set(java.util.Calendar.MILLISECOND, 0);

			return cal.getTimeInMillis();
		@}

		[Foreign(Language.Java)]
		void SetMinValue(Java.Object datePickerHandle, long msSince1970InUtc)
		@{
			android.widget.DatePicker datePicker = (android.widget.DatePicker)datePickerHandle;

			// setMinDate and setMaxDate take in milliseconds since midnight, January 1, 1970, _in getDefault()
			//  time zone_, not necessarily UTC. To compensate for this, we need to offset the incoming
			//  UTC-relative ticks by subtracting the default time zone offset. Note that the time zone offset
			//  actually depends on the incoming UTC time, as different dates will have different time offsets.

			long timezoneRelativeOffset = java.util.TimeZone.getDefault().getOffset(msSince1970InUtc);
			long javaTicksInDefaultTimezone = msSince1970InUtc - timezoneRelativeOffset;

			datePicker.setMinDate(javaTicksInDefaultTimezone);
		@}

		[Foreign(Language.Java)]
		void SetMaxValue(Java.Object datePickerHandle, long msSince1970InUtc)
		@{
			android.widget.DatePicker datePicker = (android.widget.DatePicker)datePickerHandle;

			// setMinDate and setMaxDate take in milliseconds since midnight, January 1, 1970, _in getDefault()
			//  time zone_, not necessarily UTC. To compensate for this, we need to offset the incoming
			//  UTC-relative ticks by subtracting the default time zone offset. Note that the time zone offset
			//  actually depends on the incoming UTC time, as different dates will have different time offsets.

			long timezoneRelativeOffset = java.util.TimeZone.getDefault().getOffset(msSince1970InUtc);
			long javaTicksInDefaultTimezone = msSince1970InUtc - timezoneRelativeOffset;

			datePicker.setMaxDate(javaTicksInDefaultTimezone);
		@}
	}
}
