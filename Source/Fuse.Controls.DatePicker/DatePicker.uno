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
		DateTime Value { get; set; }
		DateTime MinValue { get; set; }
		DateTime MaxValue { get; set; }

		void OnRooted();
		void OnUnrooted();
	}

	interface IDatePickerHost
	{
		void OnValueChanged();
	}

	public abstract partial class DatePickerBase : Panel, IDatePickerHost
	{
		static Selector _valueName = "Value";

		[UXOriginSetter("SetValue")]
		/**
			Gets or sets the current date value selected by the `DatePicker`. Must not be outside of the range specified by `MinValue` and `MaxValue` if these have been set.
		*/
		public DateTime Value
		{
			get
			{
				var dpv = DatePickerView;
				return dpv != null
					? dpv.Value
					: DateTime.UtcNow;
			}
			set { SetValue(value, this); }
		}

		public void SetValue(DateTime value, IPropertyListener origin)
		{
			var dpv = DatePickerView;
			if (dpv != null && dpv.Value != value)
			{
				dpv.Value = value;
				OnValueChanged(origin);
			}
		}

		internal void OnValueChanged(IPropertyListener origin)
		{
			OnPropertyChanged(_valueName, origin);
		}

		static Selector _minValueName = "MinValue";

		[UXOriginSetter("SetMinValue")]
		/**
			Gets or sets the minimum date value that can be selected by the `DatePicker`. Must not be higher than `MaxValue` if it has been specified.
		*/
		public DateTime MinValue
		{
			get
			{
				var dpv = DatePickerView;
				return dpv != null
					? dpv.MinValue
					: DateTime.UtcNow;
			}
			set { SetMinValue(value, this); }
		}

		public void SetMinValue(DateTime value, IPropertyListener origin)
		{
			var dpv = DatePickerView;
			if (dpv != null && dpv.MinValue != value)
			{
				dpv.MinValue = value;
				OnMinValueChanged(origin);
			}
		}

		internal void OnMinValueChanged(IPropertyListener origin)
		{
			OnPropertyChanged(_minValueName, origin);
		}

		static Selector _maxValueName = "MaxValue";

		[UXOriginSetter("SetMaxValue")]
		/**
			Gets or sets the maximum date value that can be selected by the `DatePicker`. Must not be lower than `MinValue` if it has been specified.
		*/
		public DateTime MaxValue
		{
			get
			{
				var dpv = DatePickerView;
				return dpv != null
					? dpv.MaxValue
					: DateTime.UtcNow;
			}
			set { SetMaxValue(value, this); }
		}

		public void SetMaxValue(DateTime value, IPropertyListener origin)
		{
			var dpv = DatePickerView;
			if (dpv != null && dpv.MaxValue != value)
			{
				dpv.MaxValue = value;
				OnMaxValueChanged(origin);
			}
		}

		internal void OnMaxValueChanged(IPropertyListener origin)
		{
			OnPropertyChanged(_maxValueName, origin);
		}

		IDatePickerView DatePickerView
		{
			get { return (IDatePickerView)NativeView; }
		}

		void IDatePickerHost.OnValueChanged()
		{
			OnValueChanged(this);
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