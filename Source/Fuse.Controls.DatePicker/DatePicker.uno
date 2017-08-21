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

		void PollViewValue();
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

		DateTime _outValue = DateTime.UtcNow;
		DateTime _inValue = DateTime.UtcNow;

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
			lock(this)
				_outValue = Value;
			OnPropertyChanged(_valueName, origin);
		}

		void UpdateValue()
		{
			lock(this)
				Value = _inValue;
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

		DateTime _outMinValue = DateTime.UtcNow;
		DateTime _inMinValue = DateTime.UtcNow;

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
			lock(this)
				_outMinValue = MinValue;
			OnPropertyChanged(_minValueName, origin);
		}

		void UpdateMinValue()
		{
			lock(this)
				MinValue = _inMinValue;
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

		DateTime _outMaxValue = DateTime.UtcNow;
		DateTime _inMaxValue = DateTime.UtcNow;

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
			lock(this)
				_outMaxValue = MaxValue;
			OnPropertyChanged(_maxValueName, origin);
		}

		void UpdateMaxValue()
		{
			lock(this)
				MaxValue = _inMaxValue;
		}

		IDatePickerView DatePickerView
		{
			get { return (IDatePickerView)NativeView; }
		}

		void PollViewValue()
		{
			var dpv = DatePickerView;
			if (dpv == null)
				return;

			dpv.PollViewValue();
		}

		void IDatePickerHost.OnValueChanged()
		{
			OnValueChanged(this);
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			_outValue = Value;
			_inValue = Value;
			_outMinValue = MinValue;
			_inMinValue = MinValue;
			_outMaxValue = MaxValue;
			_inMaxValue = MaxValue;

			UpdateManager.AddAction(PollViewValue);
		}

		protected override void OnUnrooted()
		{
			UpdateManager.RemoveAction(PollViewValue);
			base.OnUnrooted();
		}
	}
}