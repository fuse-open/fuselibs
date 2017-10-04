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
		public DatePickerView([UXParameter("Host")]IDatePickerHost host) { }
	}

	extern(Android) class DatePickerView : LeafView, IDatePickerView
	{
		IDatePickerHost _host;

		[UXConstructor]
		public DatePickerView([UXParameter("Host")]IDatePickerHost host) : base(Create())
		{
			_host = host;
			Init(Handle);
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

		public void PollViewValue()
		{
			if (Value != _pollValueCache)
			{
				OnValueChanged();
				UpdatePollValueCache();
			}
		}

		DateTime _minValue;
		public DateTime MinValue
		{
			get { return _minValue; }
			set
			{
				_minValue = value;

				SetMinValue(Handle, DateTimeConverterHelpers.ConvertDateTimeToMsSince1970InUtc(_minValue));
			}
		}

		DateTime _maxValue;
		public DateTime MaxValue
		{
			get { return _maxValue; }
			set
			{
				_maxValue = value;

				SetMaxValue(Handle, DateTimeConverterHelpers.ConvertDateTimeToMsSince1970InUtc(_maxValue));
			}
		}

		void OnValueChanged()
		{
			_host.OnValueChanged();
		}

		[Foreign(Language.Java)]
		static Java.Object Create()
		@{
			return new android.widget.DatePicker(@(Activity.Package).@(Activity.Name).GetRootActivity());
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
			//  UTC-relative ticks by subtracting the difference between the default timezone-relative epoch
			//  and the UTC-relative epoch.

			java.util.Calendar cal = java.util.Calendar.getInstance();

			cal.set(java.util.Calendar.YEAR, 1970);
			cal.set(java.util.Calendar.MONTH, 0); // Month starts at 0
			cal.set(java.util.Calendar.DAY_OF_MONTH, 1);

			cal.set(java.util.Calendar.AM_PM, java.util.Calendar.AM);
			cal.set(java.util.Calendar.HOUR, 0);
			cal.set(java.util.Calendar.MINUTE, 0);
			cal.set(java.util.Calendar.SECOND, 0);
			cal.set(java.util.Calendar.MILLISECOND, 0);

			long timezoneRelativeEpochOffset = cal.getTimeInMillis();

			long javaTicksInDefaultTimezone = msSince1970InUtc - timezoneRelativeEpochOffset;

			datePicker.setMinDate(javaTicksInDefaultTimezone);
		@}

		[Foreign(Language.Java)]
		void SetMaxValue(Java.Object datePickerHandle, long msSince1970InUtc)
		@{
			android.widget.DatePicker datePicker = (android.widget.DatePicker)datePickerHandle;

			// setMinDate and setMaxDate take in milliseconds since midnight, January 1, 1970, _in getDefault()
			//  time zone_, not necessarily UTC. To compensate for this, we need to offset the incoming
			//  UTC-relative ticks by subtracting the difference between the default timezone-relative epoch
			//  and the UTC-relative epoch.

			java.util.Calendar cal = java.util.Calendar.getInstance();

			cal.set(java.util.Calendar.YEAR, 1970);
			cal.set(java.util.Calendar.MONTH, 0); // Month starts at 0
			cal.set(java.util.Calendar.DAY_OF_MONTH, 1);

			cal.set(java.util.Calendar.AM_PM, java.util.Calendar.AM);
			cal.set(java.util.Calendar.HOUR, 0);
			cal.set(java.util.Calendar.MINUTE, 0);
			cal.set(java.util.Calendar.SECOND, 0);
			cal.set(java.util.Calendar.MILLISECOND, 0);

			long timezoneRelativeEpochOffset = cal.getTimeInMillis();

			long javaTicksInDefaultTimezone = msSince1970InUtc - timezoneRelativeEpochOffset;

			datePicker.setMaxDate(javaTicksInDefaultTimezone);
		@}
	}
}
