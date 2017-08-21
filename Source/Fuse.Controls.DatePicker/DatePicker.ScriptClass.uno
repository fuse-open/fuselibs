using Uno;
using Uno.Text;
using Uno.UX;

using Fuse;
using Fuse.Controls.Native;
using Fuse.Scripting;

namespace Fuse.Controls
{
	public partial class DatePickerBase
	{
		class ValueProperty : Property<DateTime>
		{
			readonly DatePickerBase _dp;
			public override PropertyObject Object { get { return _dp; } }
			public override bool SupportsOriginSetter { get { return false; } }
			public override DateTime Get(PropertyObject obj)
			{
				DateTime date = DateTime.UtcNow;
				lock(_dp)
					date = _dp._outValue;
				return date;
			}
			public override void Set(PropertyObject obj, DateTime value, IPropertyListener origin)
			{
				lock(_dp)
					_dp._inValue = value;
				UpdateManager.PostAction(_dp.UpdateValue);
			}
			public ValueProperty(DatePickerBase datePicker) : base(DatePickerBase._valueName) { _dp = datePicker; }
		}

		class MinValueProperty : Property<DateTime>
		{
			readonly DatePickerBase _dp;
			public override PropertyObject Object { get { return _dp; } }
			public override bool SupportsOriginSetter { get { return false; } }
			public override DateTime Get(PropertyObject obj)
			{
				DateTime date = DateTime.UtcNow;
				lock(_dp)
					date = _dp._outMinValue;
				return date;
			}
			public override void Set(PropertyObject obj, DateTime value, IPropertyListener origin)
			{
				lock(_dp)
					_dp._inMinValue = value;
				UpdateManager.PostAction(_dp.UpdateMinValue);
			}
			public MinValueProperty(DatePickerBase datePicker) : base(DatePickerBase._minValueName) { _dp = datePicker; }
		}

		class MaxValueProperty : Property<DateTime>
		{
			readonly DatePickerBase _dp;
			public override PropertyObject Object { get { return _dp; } }
			public override bool SupportsOriginSetter { get { return false; } }
			public override DateTime Get(PropertyObject obj)
			{
				DateTime date = DateTime.UtcNow;
				lock(_dp)
					date = _dp._outMaxValue;
				return date;
			}
			public override void Set(PropertyObject obj, DateTime value, IPropertyListener origin)
			{
				lock(_dp)
					_dp._inMaxValue = value;
				UpdateManager.PostAction(_dp.UpdateMaxValue);
			}
			public MaxValueProperty(DatePickerBase datePicker) : base(DatePickerBase._maxValueName) { _dp = datePicker; }
		}

		static DatePickerBase()
		{
			ScriptClass.Register(typeof(DatePickerBase),
				new ScriptProperty<DatePickerBase, DateTime>("value", GetValueProperty),
				new ScriptProperty<DatePickerBase, DateTime>("minDate", GetMinValueProperty),
				new ScriptProperty<DatePickerBase, DateTime>("maxDate", GetMaxValueProperty));
		}

		ValueProperty _valueProperty;
		/**
			@scriptproperty value

			A JS proxy for the `Value` property with JS' `Date` type.
		*/
		static Property<DateTime> GetValueProperty(DatePickerBase datePicker)
		{
			if (datePicker._valueProperty == null)
				datePicker._valueProperty = new ValueProperty(datePicker);

			return datePicker._valueProperty;
		}

		MinValueProperty _minValueProperty;
		/**
			@scriptproperty minValue

			A JS proxy for the `MinValue` property with JS' `Date` type.
		*/
		static Property<DateTime> GetMinValueProperty(DatePickerBase datePicker)
		{
			if (datePicker._minValueProperty == null)
				datePicker._minValueProperty = new MinValueProperty(datePicker);

			return datePicker._minValueProperty;
		}

		MaxValueProperty _maxValueProperty;
		/**
			@scriptproperty maxValue

			A JS proxy for the `MaxValue` property with JS' `Date` type.
		*/
		static Property<DateTime> GetMaxValueProperty(DatePickerBase datePicker)
		{
			if (datePicker._maxValueProperty == null)
				datePicker._maxValueProperty = new MaxValueProperty(datePicker);

			return datePicker._maxValueProperty;
		}

	}
}