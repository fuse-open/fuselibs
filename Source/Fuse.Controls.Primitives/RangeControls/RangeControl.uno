using Uno;
using Uno.Platform;
using Uno.UX;
using Fuse.Input;
using Fuse.Triggers;
using Fuse.Controls.Native;

namespace Fuse.Controls
{
	/** Baseclass for controls that contains a range value
		
		This is the baseclass for @Controls that hold a range value. For example @Slider.
		
		RangeControl is what you want to use if your component will hold a range value,
		RangeControl support for example @ProgressAnimation which makes it nice to use in
		animation.

		## Example

			<StackPanel>

				<RangeControl ux:Class="CustomSlider" Padding="16,2,16,2" Margin="2" >
					<LinearRangeBehavior />
					<Panel>
						<Circle Anchor="50%,50%" ux:Name="thumb" Alignment="Left" Color="#ffffffee" Width="28" Height="28" />
					</Panel>
					<Rectangle Layer="Background" Color="#aaaaaacc" CornerRadius="45" />
					<ProgressAnimation>
						<Move Target="thumb" X="1" RelativeTo="ParentSize" />
					</ProgressAnimation>
				</RangeControl>

				<CustomSlider />

			</StackPanel>

		## Available RangeControl classes

		[subclass Fuse.Controls.RangeControl]

	*/
	public class RangeControl: Panel, IProgress, IValue<double>, IRangeViewHost
	{
		double _minimum = 0.0f;
		/** Minimum value of the RangeControl. Defaults to 0*/
		public double Minimum
		{
			get { return _minimum; }
			set 
			{ 
				if (_minimum != value)
				{
					_minimum = value;
					OnRangeChanged();
				}
			}
		}

		double _maximum = 100.0f;
		/** Maximum value of the RangeControl. Defaults to 100 */
		public double Maximum
		{
			get { return _maximum; }
			set 
			{ 
				if (_maximum != value)
				{
					_maximum = value;
					OnRangeChanged();
				}
			}
		}

		double _value = 0.0;
		[UXOriginSetter("SetValue")]
		public double Value
		{
			get { return _value; }
			set { SetValue(value, this); }
		}
		
		static Selector _valueName = "Value";

		IRangeView RangeView
		{
			get { return NativeView as IRangeView; }
		}

		protected override void PushPropertiesToNativeView()
		{
			var r = RangeView;
			if (r != null)
			{
				r.Progress = ValueToRelative(Value);
			}
		}

		public void SetValue(double value, IPropertyListener origin)
		{
			var v = ClampToRange(value);

			if (v != _value)
			{
				_value = v;
				OnValueChanged(v, origin);
			}

			if (origin != null)
			{
				var rv = RangeView;
				if (rv != null)
				{
					rv.Progress = ValueToRelative(value);
				}
			}
		}

		public double RelativeValue
		{
			get { return ValueToRelative(Value); }
			set { Value = ValueFromRelative(value); }
		}

		double _userStep;
		/** 	
			Quantizes user selection to this step. This is enforced by the behavior and not by this
			control. The control can still have non-quantized values (allowing animation).
		*/
		public double UserStep
		{
			get { return _userStep; }
			set { _userStep = value; }
		}
		
		public double RelativeUserStep
		{
			get { return ValueToRelative(UserStep); }
			set { UserStep = ValueFromRelative(value); }
		}

		double ClampToRange(double v)
		{
			return Math.Min(Math.Max(Minimum, v), Maximum);
		}

		public event ValueChangedHandler<double> ValueChanged;
		
		public event ValueChangedHandler<double> ProgressChanged
		{
			add { ValueChanged += value; }
			remove { ValueChanged -= value; }
		}

		void OnRangeChanged()
		{
			// Makes sure value is still clamped to range, and raises ValueChanged if this
			// leads to a change
			SetValue(Value, null);
			OnProgressChanged();
		}

		void OnValueChanged(double value, IPropertyListener origin)
		{
			OnPropertyChanged(_valueName, origin);

			if (ValueChanged != null)
				ValueChanged(this, new Fuse.Scripting.DoubleChangedArgs(value));

			OnProgressChanged();
		}

		static Selector _progressName = "Progress";
		protected virtual void OnProgressChanged()
		{
			OnPropertyChanged(_progressName);
		}

		public double Progress
		{
			get { return ValueToRelative(Value); }
			set { Value = ValueFromRelative(value); }
		}
		
		internal double ValueFromRelative(double relative)
		{
			return relative * (Maximum - Minimum) + Minimum;
		}
		
		internal double ValueToRelative(double value)
		{
			return (value - Minimum) / (Maximum - Minimum);
		}

		void IRangeViewHost.OnProgressChanged(double newProgress)
		{
			SetValue(ValueFromRelative(newProgress), null);	
		}
	}
}
