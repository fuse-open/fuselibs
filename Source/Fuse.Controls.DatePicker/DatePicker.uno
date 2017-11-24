using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;

using Fuse;
using Fuse.Controls.Native;
using Fuse.Scripting;

namespace Fuse.Controls
{
	using Native.iOS;
	using Native.Android;

	interface IDatePickerView
	{
		DateTime Value { set; }
		DateTime MinValue { set; }
		DateTime MaxValue { set; }

		void OnRooted();
		void OnUnrooted();
	}

	public abstract partial class DatePickerBase : Panel
	{
		static Selector _valueName = "Value";

		DateTime _value = DateTime.UtcNow;
		[UXOriginSetter("SetValue")]
		/**
			Gets or sets the current date value selected by the `DatePicker`. Must not be outside of the range specified by `MinValue` and `MaxValue` if these have been set.
		*/
		public DateTime Value
		{
			get { return _value; }
			set { SetValue(value, this); }
		}

		public void SetValue(DateTime value, IPropertyListener origin)
		{
			UpdateValue(value, origin);

			var dpv = DatePickerView;
			if (dpv != null)
				dpv.Value = value;
		}

		void UpdateValue(DateTime value, IPropertyListener origin)
		{
			if (value != _value)
			{
				_value = value;
				OnValueChanged(origin);
			}
		}

		internal void OnValueChanged(IPropertyListener origin)
		{
			OnPropertyChanged(_valueName, origin);
		}

		internal void OnNativeViewValueChanged(DateTime newValue)
		{
			UpdateValue(newValue, this);
		}

		static Selector _minValueName = "MinValue";

		DateTime _minValue;
		[UXOriginSetter("SetMinValue")]
		/**
			Gets or sets the minimum date value that can be selected by the `DatePicker`. Must not be higher than `MaxValue` if it has been specified.
		*/
		public DateTime MinValue
		{
			get { return _minValue; }
			set { SetMinValue(value, this); }
		}

		public void SetMinValue(DateTime value, IPropertyListener origin)
		{
			if (value != _minValue)
			{
				_minValue = value;
				OnMinValueChanged(origin);
			}

			var dpv = DatePickerView;
			if (dpv != null)
				dpv.MinValue = value;
		}

		internal void OnMinValueChanged(IPropertyListener origin)
		{
			OnPropertyChanged(_minValueName, origin);
		}

		static Selector _maxValueName = "MaxValue";

		DateTime _maxValue;
		[UXOriginSetter("SetMaxValue")]
		/**
			Gets or sets the maximum date value that can be selected by the `DatePicker`. Must not be lower than `MinValue` if it has been specified.
		*/
		public DateTime MaxValue
		{
			get { return _maxValue; }
			set { SetMaxValue(value, this); }
		}

		public void SetMaxValue(DateTime value, IPropertyListener origin)
		{
			if (value != _maxValue)
			{
				_maxValue = value;
				OnMaxValueChanged(origin);
			}

			var dpv = DatePickerView;
			if (dpv != null)
				dpv.MaxValue = value;
		}

		internal void OnMaxValueChanged(IPropertyListener origin)
		{
			OnPropertyChanged(_maxValueName, origin);
		}

		IDatePickerView DatePickerView
		{
			get { return (IDatePickerView)NativeView; }
		}

		protected override void OnRooted()
		{
			base.OnRooted();

			var dpv = DatePickerView;
			if (dpv != null)
				dpv.OnRooted();
		}

		protected override void OnUnrooted()
		{
			var dpv = DatePickerView;
			if (dpv != null)
				dpv.OnUnrooted();

			base.OnUnrooted();
		}
	}
}
