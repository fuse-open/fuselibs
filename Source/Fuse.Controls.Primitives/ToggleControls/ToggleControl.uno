using Uno;
using Uno.UX;
using Fuse.Input;
using Fuse.Gestures;
using Fuse.Animations;
using Fuse.Elements;
using Fuse.Triggers;
using Fuse.Triggers.Actions;
using Fuse.Controls.Native;
using Fuse.Scripting;

namespace Fuse.Controls
{
	/** Panel that contains a toggleable value 

		Panel type that is suitable for making toggleable semantic controls,
		like Switch, CheckBox, ToggleButton etc.

		## Example

			<ToggleControl ux:Class="CheckBox" BoxSizing="FillAspect" Aspect="1" Margin="2" HitTestMode="LocalBounds" Width="48" Height="48">
				<Rectangle Color="#999" Margin="4" ux:Name="_toggledBox" Opacity="0" />
				<WhileTrue Value="{ReadProperty this.Value}">
					<Change _toggledBox.Opacity="1" Duration="0.15" Easing="CubicOut" EasingBack="CubicIn" />
				</WhileTrue>
				<Rectangle Layer="Background">
					<Stroke Color="#000" />
				</Rectangle>
				<Clicked>
					<Toggle Target="this" />
				</Clicked>
			</ToggleControl>

	*/
	public class ToggleControl: Panel, IValue<bool>, IToggleViewHost, IToggleable
	{
		static Selector _valueName = "Value";

		IToggleView ToggleView
		{
			get { return NativeView as IToggleView; }
		}

		bool _value;
		[UXOriginSetter("SetValue")]
		/**
			The toggleable value of ToggleControl
		*/
		public bool Value
		{
			get { return _value; }
			set { SetValue(value, this); }
		}
		public void SetValue(bool value, IPropertyListener origin)
		{
			if (_value != value)
			{
				_value = value;
				OnValueChanged(value, origin);
				OnPropertyChanged(_valueName, origin);

				if (origin != null)
				{
					var tv = ToggleView;
					if (tv != null)
					{
						tv.Value = value;
					}
				}
			}
		}

		public void Toggle()
		{
			Value = !Value;
		}

		protected override void PushPropertiesToNativeView()
		{
			var tv = ToggleView;
			if (tv != null)
			{
				tv.Value = Value;
			}
		}

		protected virtual void OnValueChanged(bool value, IPropertyListener origin)
		{
			if (ValueChanged != null)
				ValueChanged(this, new BoolChangedArgs(value));
		}

		void IToggleViewHost.OnValueChanged(bool newValue)
		{
			SetValue(newValue, null);
		}

		public event ValueChangedHandler<bool> ValueChanged;
	}

}
