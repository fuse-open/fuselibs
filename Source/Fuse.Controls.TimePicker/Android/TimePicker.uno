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
		Java.Object _timePicker;
		Java.Object _timeLabel;

		[UXConstructor]
		public TimePickerView([UXParameter("Host")]TimePicker host) : base(Create())
		{
			_host = host;

			Style = _host.Style;
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

		TimePickerStyle _style = TimePickerStyle.Default;
		public TimePickerStyle Style
		{
			get { return _style; }
			set
			{
				_style = value;
				switch (value)
				{
					case TimePickerStyle.Default:
					case TimePickerStyle.Inline:
					case TimePickerStyle.Wheels:
						SetStyle(Handle, 0);
						break;
					case TimePickerStyle.Compact:
						SetStyle(Handle, 1);
						break;
				}
				SetTime(_timePicker, _timeLabel, DateTimeConverterHelpers.ConvertDateTimeToMsSince1970InUtc(_pollValueCache));
			}
		}

		public DateTime Value
		{
			get
			{
				var msSince1970InUtc = GetTimeInMsSince1970InUtc(_timePicker);
				return DateTimeConverterHelpers.ConvertMsSince1970InUtcToDateTime(msSince1970InUtc);
			}
			set
			{
				SetTime(_timePicker, _timeLabel, DateTimeConverterHelpers.ConvertDateTimeToMsSince1970InUtc(value));
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
				SetTime(_timePicker, _timeLabel, DateTimeConverterHelpers.ConvertDateTimeToMsSince1970InUtc(Value));
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
			set { SetIs24HourView(_timePicker, value); }
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
			java.util.Calendar cal = java.util.Calendar.getInstance(java.util.TimeZone.getTimeZone("UTC"), java.util.Locale.getDefault());

			int hour = cal.get(java.util.Calendar.HOUR);
			if (cal.get(java.util.Calendar.AM_PM) == java.util.Calendar.PM)
				hour += 12;
			int minute = cal.get(java.util.Calendar.MINUTE);

			android.widget.FrameLayout frameLayout = (android.widget.FrameLayout)handle;
			frameLayout.removeAllViews();
			if (style == 1) {
				final com.fuse.android.widget.FuseTimePickerDialog pickerDialog = new com.fuse.android.widget.FuseTimePickerDialog(com.fuse.Activity.getRootActivity(), null, hour, minute, false);
				android.widget.TextView textview = new android.widget.TextView(com.fuse.Activity.getRootActivity());
				textview.setTextSize(android.util.TypedValue.COMPLEX_UNIT_SP,16);
				textview.setTextColor(android.graphics.Color.parseColor("#555555"));
				textview.setOnClickListener(new android.view.View.OnClickListener() {
					@Override
					public void onClick(android.view.View v) {
						pickerDialog.show();
					}
				});
				frameLayout.addView(textview);
				@{TimePickerView:Of(_this)._timePicker:Set(pickerDialog.getTimePicker())};
				@{TimePickerView:Of(_this)._timeLabel:Set(textview)};
			}
			else {
				android.widget.TimePicker timePicker = new android.widget.TimePicker(com.fuse.Activity.getRootActivity());
				if (android.os.Build.VERSION.SDK_INT >= 23) {
					timePicker.setHour(hour);
					timePicker.setMinute(minute);
				} else {
					timePicker.setCurrentHour(hour);
					timePicker.setCurrentMinute(minute);
				}
				@{TimePickerView:Of(_this)._timePicker:Set(timePicker)};
				frameLayout.addView(timePicker);
			}
		@}

		[Foreign(Language.Java)]
		void SetTime(Java.Object timePickerHandle, Java.Object timeLabelHandle, long msSince1970InUtc)
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
			android.widget.TextView textview = (android.widget.TextView)timeLabelHandle;
			if (textview != null) {
				String pattern = timePicker.is24HourView() ? "HH:mm" : "hh:mm";
				java.text.SimpleDateFormat simpleDateFormat = new java.text.SimpleDateFormat(pattern);
				textview.setText(simpleDateFormat.format(cal.getTime()));
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
