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
		DateTime Value { get; set; }
		bool Is24HourView { get; set; }

		void OnRooted();
		void OnUnrooted();
	}

	interface ITimePickerHost
	{
		void OnValueChanged();
	}

	public abstract partial class TimePickerBase : Panel, ITimePickerHost
	{
		static Selector _valueName = "Value";

		[UXOriginSetter("SetValue")]
		/**
			Gets or sets the current time value selected by the `TimePicker`.
		*/
		public DateTime Value
		{
			get
			{
				var tpv = TimePickerView;
				return tpv != null
					? tpv.Value
					: DateTime.UtcNow;
			}
			set { SetValue(value, this); }
		}

		public void SetValue(DateTime value, IPropertyOrigin origin)
		{
			var tpv = TimePickerView;
			if (tpv != null && tpv.Value != value)
			{
				tpv.Value = value;
				OnValueChanged(origin);
			}
		}

		internal void OnValueChanged(IPropertyOrigin origin)
		{
			OnPropertyChanged(_valueName, origin);
		}

		static Selector _is24HourViewName = "Is24HourView";

		[UXOriginSetter("SetIs24HourView")]
		/**
			Used to toggle 24-hour or am/pm view. Default is false (am/pm).

			Currently only implemented for Android, as iOS doesn't expose an explicit API for this.
		*/
		public bool Is24HourView
		{
			get
			{
				var tpv = TimePickerView;
				return tpv != null
					? tpv.Is24HourView
					: false;
			}
			set { SetIs24HourView(value, this); }
		}

		public void SetIs24HourView(bool value, IPropertyOrigin origin)
		{
			var tpv = TimePickerView;
			if (tpv != null && tpv.Is24HourView != value)
			{
				tpv.Is24HourView = value;
				OnIs24HourViewChanged(origin);
			}
		}

		internal void OnIs24HourViewChanged(IPropertyOrigin origin)
		{
			OnPropertyChanged(_is24HourViewName, origin);
		}

		ITimePickerView TimePickerView
		{
			get { return (ITimePickerView)NativeView; }
		}

		void ITimePickerHost.OnValueChanged()
		{
			OnValueChanged(this);
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
