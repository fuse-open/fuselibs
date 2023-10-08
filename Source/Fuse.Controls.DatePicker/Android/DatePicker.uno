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
		Java.Object _datePicker;
		Java.Object _dateLabel;

		[UXConstructor]
		public DatePickerView([UXParameter("Host")]DatePicker host) : base(Create())
		{
			_host = host;
			// The native control might reject values outside of the min/max range, so make sure we set min/max first
			Style = _host.Style;
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

		DatePickerStyle _style = DatePickerStyle.Default;
		public DatePickerStyle Style
		{
			get { return _style; }
			set
			{
				_style = value;
				switch (value)
				{
					case DatePickerStyle.Default:
					case DatePickerStyle.Inline:
					case DatePickerStyle.Wheels:
						SetStyle(Handle, 0);
						break;
					case DatePickerStyle.Compact:
						SetStyle(Handle, 1);
						break;
				}
				SetDate(_datePicker, _dateLabel, DateTimeConverterHelpers.ConvertDateTimeToMsSince1970InUtc(_pollValueCache));
			}
		}

		public DateTime Value
		{
			get
			{
				var msSince1970InUtc = GetDateInMsSince1970InUtc(_datePicker);
				return DateTimeConverterHelpers.ConvertMsSince1970InUtcToDateTime(msSince1970InUtc);
			}
			set
			{
				SetDate(_datePicker, _dateLabel, DateTimeConverterHelpers.ConvertDateTimeToMsSince1970InUtc(value));
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
				SetDate(_datePicker, _dateLabel, DateTimeConverterHelpers.ConvertDateTimeToMsSince1970InUtc(Value));
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
			writebackFrameCounter = 0;
		}

		void UpdateWriteback()
		{
			if (writebackFrameCounter < 2)
			{
				writebackFrameCounter++;
				if (writebackFrameCounter == 2)
				{
					var v = DateTimeConverterHelpers.ConvertDateTimeToMsSince1970InUtc(Value);
					SetDate(_datePicker, _dateLabel, v - 1); // Write temp value, as the picker won't scroll unless the value actually changes
					SetDate(_datePicker, _dateLabel, v);
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
			_datePicker = null;
			_dateLabel = null;
		}

		void OnValueChanged(DateTime value)
		{
			_host.OnNativeViewValueChanged(value);
		}

		public DateTime MinValue
		{
			set { SetMinValue(_datePicker, DateTimeConverterHelpers.ConvertDateTimeToMsSince1970InUtc(value)); }
		}

		public DateTime MaxValue
		{
			set { SetMaxValue(_datePicker, DateTimeConverterHelpers.ConvertDateTimeToMsSince1970InUtc(value)); }
		}

		[Foreign(Language.Java)]
		static Java.Object Create()
		@{
			android.widget.FrameLayout frameLayout = new android.widget.FrameLayout(com.fuse.Activity.getRootActivity());
			frameLayout.setLayoutParams(new android.widget.FrameLayout.LayoutParams(android.view.ViewGroup.LayoutParams.MATCH_PARENT, android.view.ViewGroup.LayoutParams.MATCH_PARENT));
			return frameLayout;
		@}

		[Foreign(Language.Java)]
		void SetStyle(Java.Object handle, int style)
		@{
			android.widget.FrameLayout frameLayout = (android.widget.FrameLayout)handle;
			frameLayout.removeAllViews();
			// Use local calendar to get default year/month/day
			java.util.Calendar cal = java.util.Calendar.getInstance();

			int y = cal.get(java.util.Calendar.YEAR);
			int m = cal.get(java.util.Calendar.MONTH);
			int d = cal.get(java.util.Calendar.DAY_OF_MONTH);

			if (style == 1) { // compact
				final android.app.DatePickerDialog pickerDialog = new android.app.DatePickerDialog(com.fuse.Activity.getRootActivity());

				java.text.DateFormat dateFormat = android.text.format.DateFormat.getMediumDateFormat(com.fuse.Activity.getRootActivity());
				android.widget.TextView textview = new android.widget.TextView(com.fuse.Activity.getRootActivity());
				textview.setTextSize(android.util.TypedValue.COMPLEX_UNIT_SP,16);
				textview.setTextColor(android.graphics.Color.parseColor("#555555"));
				textview.setText(dateFormat.format(cal.getTime()));
				textview.setOnClickListener(new android.view.View.OnClickListener() {
					@Override
					public void onClick(android.view.View v) {
						pickerDialog.show();
					}
				});
				frameLayout.addView(textview);
				@{DatePickerView:of(_this)._datePicker:set(pickerDialog.getDatePicker())};
				@{DatePickerView:of(_this)._dateLabel:set(textview)};
			} else {
				android.widget.DatePicker datePicker = new android.widget.DatePicker(com.fuse.Activity.getRootActivity());
				datePicker.setLayoutParams(new android.widget.FrameLayout.LayoutParams(android.view.ViewGroup.LayoutParams.MATCH_PARENT, android.view.ViewGroup.LayoutParams.MATCH_PARENT));
				datePicker.init(y, m, d, null);
				@{DatePickerView:of(_this)._datePicker:set(datePicker)};
				frameLayout.addView(datePicker);
			}
		@}

		[Foreign(Language.Java)]
		void SetDate(Java.Object datePickerHandle, Java.Object dateLabelHandle, long msSince1970InUtc)
		@{
			java.util.Calendar cal = java.util.Calendar.getInstance(java.util.TimeZone.getTimeZone("UTC"), java.util.Locale.getDefault());
			cal.setTimeInMillis(msSince1970InUtc);

			int y = cal.get(java.util.Calendar.YEAR);
			int m = cal.get(java.util.Calendar.MONTH);
			int d = cal.get(java.util.Calendar.DAY_OF_MONTH);

			android.widget.DatePicker datePicker = (android.widget.DatePicker)datePickerHandle;
			datePicker.updateDate(y, m, d);
			android.widget.TextView textview = (android.widget.TextView)dateLabelHandle;
			if (textview != null) {
				java.text.DateFormat dateFormat = android.text.format.DateFormat.getMediumDateFormat(com.fuse.Activity.getRootActivity());
				textview.setText(dateFormat.format(cal.getTime()));
			}
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
