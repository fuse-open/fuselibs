using Uno;
using Uno.UX;

using Fuse.Triggers;

namespace Fuse.Controls
{
	/**
		@mount UI Components / Abstract
	*/
	public class RangeControl2D: Panel, IValue<float2>
	{
		float2 _minimum = float2(0);
		public float2 Minimum
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

		float2 _maximum = float2(100);
		public float2 Maximum
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

		float2 _value;
		[UXOriginSetter("SetValue")]
		public float2 Value
		{
			get { return _value; }
			set { SetValue(value, this); }
		}

		static Selector _valueName = "Value";
		static Selector _valueXName = "ValueX";
		static Selector _valueYName = "ValueY";

		public void SetValue(float2 value, IPropertyListener origin)
		{
			if (value != _value)
			{
				_value = value;
				OnValueChanged(value, origin);
			}
		}

		public float2 RelativeValue
		{
			get { return ValueToRelative(Value); }
			set { Value = ValueFromRelative(value); }
		}
		
		float2 _userStep;
		/** 	
			Quantizes user selection to this step. This is enforced by the behavior and not by this
			control. The control can still have non-quantized values (allowing animation).
		*/
		public float2 UserStep
		{
			get { return _userStep; }
			set { _userStep = value; }
		}
		
		public float2 RelativeUserStep
		{
			get { return ValueToRelative(UserStep); }
			set { UserStep = ValueFromRelative(value); }
		}

		public event ValueChangedHandler<float2> ValueChanged;
		public event ValueChangedHandler<float> ValueXChanged;
		public event ValueChangedHandler<float> ValueYChanged;
		
		void OnRangeChanged()
		{
		}

		void OnValueChanged(float2 value, IPropertyListener origin)
		{
			OnPropertyChanged(_valueName, origin);
			OnPropertyChanged(_valueXName, origin);
			OnPropertyChanged(_valueYName, origin);

			if (ValueChanged != null)
				ValueChanged(this, new ValueChangedArgs<float2>(value));
			if (ValueXChanged != null)
				ValueXChanged(this, new ValueChangedArgs<float>(value.X));
			if (ValueYChanged != null)
				ValueYChanged(this, new ValueChangedArgs<float>(value.Y));
		}

		internal float2 ValueFromRelative(float2 relative)
		{
			return relative * (Maximum - Minimum) + Minimum;
		}
		
		internal float2 ValueToRelative(float2 value)
		{
			var range = Maximum - Minimum;
			const float zeroTolerance = 1e-05f;
			var x = Math.Abs(range.X) > zeroTolerance ? value.X/range.X : 
				(value.X >= Maximum.X ? 1 : 0);
			var y = Math.Abs(range.Y) > zeroTolerance ? value.Y/range.Y :
				(value.Y >= Maximum.Y ? 1 : 0);
			return float2(x,y);
		}
		
		[UXOriginSetter("SetValueX")]
		public float ValueX
		{
			get { return Value.X; }
			set { Value = float2(value,Value.Y); }
		}

		public void SetValueX(float value, IPropertyListener origin)
		{
			SetValue(float2(value,Value.Y),origin);
		}
		
		[UXOriginSetter("SetValueY")]
		public float ValueY
		{
			get { return Value.Y; }
			set { Value = float2(Value.X,value); }
		}

		public void SetValueY(float value, IPropertyListener origin)
		{
			SetValue(float2(Value.X,value),origin);
		}
	}
}
