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

	interface ITimePickerView
	{
		DateTime Value { set; }
		bool Is24HourView { set; }

		void OnRooted();
		void OnUnrooted();
	}

	public abstract partial class TimePickerBase : Panel
	{
		static Selector _valueName = "Value";

		DateTime _value = DateTime.UtcNow;
		[UXOriginSetter("SetValue")]
		/**
			Gets or sets the current time value selected by the `TimePicker`.
		*/
		public DateTime Value
		{
			get { return _value; }
			set { SetValue(value, this); }
		}

		public void SetValue(DateTime value, IPropertyListener origin)
		{
			UpdateValue(value, origin);

			var tpv = TimePickerView;
			if (tpv != null)
				tpv.Value = value;
		}

		void UpdateValue(DateTime value, IPropertyListener origin)
		{
			if (value != _value)
			{
				_value = value;
				OnValueChanged(origin);
			}
		}

		void OnValueChanged(IPropertyListener origin)
		{
			OnPropertyChanged(_valueName, origin);
		}

		internal void OnNativeViewValueChanged(DateTime newValue)
		{
			UpdateValue(newValue, this);
		}

		static Selector _is24HourViewName = "Is24HourView";

		bool _is24HourView;
		[UXOriginSetter("SetIs24HourView")]
		/**
			Used to toggle 24-hour or am/pm view. Default is false (am/pm).

			Currently only implemented for Android, as iOS doesn't expose an explicit API for this.
		*/
		public bool Is24HourView
		{
			get { return _is24HourView; }
			set { SetIs24HourView(value, this); }
		}

		public void SetIs24HourView(bool value, IPropertyListener origin)
		{
			if (value != _is24HourView)
			{
				_is24HourView = value;
				OnIs24HourViewChanged(origin);
			}

			var tpv = TimePickerView;
			if (tpv != null)
				tpv.Is24HourView = value;
		}

		void OnIs24HourViewChanged(IPropertyListener origin)
		{
			OnPropertyChanged(_is24HourViewName, origin);
		}

		ITimePickerView TimePickerView
		{
			get { return (ITimePickerView)NativeView; }
		}

		protected override void OnRooted()
		{
			base.OnRooted();

			var tpv = TimePickerView;
			if (tpv != null)
				tpv.OnRooted();
		}

		protected override void OnUnrooted()
		{
			var tpv = TimePickerView;
			if (tpv != null)
				tpv.OnUnrooted();

			base.OnUnrooted();
		}
	}
}
