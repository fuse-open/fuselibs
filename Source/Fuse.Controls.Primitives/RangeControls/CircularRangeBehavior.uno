using Uno;
using Uno.UX;

using Fuse.Controls;
using Fuse.Elements;
using Fuse.Input;
using Fuse.Triggers;

namespace Fuse.Gestures
{
	struct double2 
	{ 
		public double X; 
		public double Y; 
		
		public double2(double x, double y)
		{
			X = x;
			Y = y;
		}
		
		public double2(float2 v)
		{
			X = v.X;
			Y = v.Y;
		}
		
		public float2 AsFloat2
		{
			get { return float2((float)X,(float)Y); }
		}
	}

	/** Helper class for implementing circular @(RangeControl:RangeControls)
	
		Used to enable circual touch input on @RangeControl.
		Typically used when implementing circular range pickers,
		like a clock timepicker or dials.

		## Example
		
		### Andgle-based circular range control
		The following example shows a simple circular @(RangeControl) implemented using `CircularRangeBehavior`, where a visual is rotated as the @(RangeControl) is changed. The range is calculated from the angle between the mouse and the X-axis

			<RangeControl Width="180" Height="180" Margin="2">
				<CircularRangeBehavior />
				<Panel ux:Name="thumb" Margin="4">
					<Rectangle Color="#fff" Alignment="Right" Height="18" Width="48" CornerRadius="4" />
				</Panel>
				<ProgressAnimation>
					<Rotate Target="thumb" Degrees="360" />
				</ProgressAnimation>
				<Circle Color="#aaa" />
			</RangeControl>
		
		### Angle and radius based circular range control
		When used with a @(RangeControl2D), you can get both the angle progress, and the radius progress. This effectively means that your range control allows the user to control two ranges at once.
		
			<RangeControl2D Width="180" Height="180" Margin="2" ux:Name="rangeControl">
				<CircularRangeBehavior/>
				<Panel ux:Name="thumb" Margin="4">
					<Rectangle Color="#fff" Alignment="Right" Height="18" Width="48" CornerRadius="4" />
				</Panel>
				<RangeAnimation Minimum="0" Maximum="100" Value="{ReadProperty rangeControl.ValueX}">
					<Rotate Target="thumb" Degrees="360" />
				</RangeAnimation>
				<RangeAnimation Minimum="0" Maximum="100" Value="{ReadProperty rangeControl.ValueY}">
					<Change radiusCircle.Factor="1" />
				</RangeAnimation>
				<Circle Color="#0FF" Alignment="Center" Width="180" Height="180">
					<Scaling ux:Name="radiusCircle" Factor="0" />
				</Circle>
				<Circle Color="#aaa" />
			</RangeControl2D>
	*/
	public class CircularRangeBehavior : Behavior
	{
		const float _angleHardThreshold = Math.PIf/180*5;
		const float _radiusHardThreshold = 5;
		
		Element _control;
		RangeControl _rangeControl;
		RangeControl2D _binaryRangeControl;

		float _startAngle = 0;
		/** The minimum angle for which the range controller will register rotation. */
		public float StartAngleDegrees
		{
			get { return Math.RadiansToDegrees(_startAngle); }
			set { _startAngle = Math.DegreesToRadians(value); }
		}
		
		float _endAngle = 2 * Math.PIf;
		/** The maximum angle for which the range controller will register rotation. */
		public float EndAngleDegrees
		{
			get { return Math.RadiansToDegrees(_endAngle); }
			set { _endAngle = Math.DegreesToRadians(value); }
		}
		
		float _minimumRadius = 0;
		/** The minimum radius the range controller will map to. */
		public float MinimumRadius
		{
			get { return _minimumRadius; }
			set { _minimumRadius = value; }
		}
		
		float _maximumRadius = 1;
		/** The maximum radius the range controller will map to. */
		public float MaximumRadius
		{
			get { return _maximumRadius; }
			set { _maximumRadius = value; }
		}
		
		bool _wrap = false;
		/** Prevents `DegreesValue` from being 360. Sets it to 0 instead. */
		public bool IsWrapping
		{
			get { return _wrap; }
			set { _wrap = value; }
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();
			
			_control = Parent as Element;
			_rangeControl = Parent as RangeControl;
			_binaryRangeControl = Parent as RangeControl2D;
			
			if (_rangeControl == null && _binaryRangeControl == null)
			{
				Fuse.Diagnostics.UserRootError( "RangeControl or BinaryRangeControl", Parent, this );
			}
			else
			{
				Pointer.AddHandlers(_control, OnPointerPressed, OnPointerMoved, OnPointerReleased);
				if (_rangeControl != null)
					_rangeControl.ValueChanged += OnValueChanged;
				else
					_binaryRangeControl.ValueChanged += OnValueChanged;
			}
		}
		
		protected override void OnUnrooted()
		{
			if (_control != null)
				Pointer.RemoveHandlers(_control, OnPointerPressed, OnPointerMoved, OnPointerReleased);
			if (_rangeControl != null)
				_rangeControl.ValueChanged -= OnValueChanged;
			if (_binaryRangeControl != null)
				_binaryRangeControl.ValueChanged -= OnValueChanged;
			_control = null;
			_rangeControl = null;
			_binaryRangeControl = null;
			base.OnUnrooted();
		}
		
		void OnLostCapture()
		{
			if (_rangeControl != null)
				_rangeControl.Value = _initialValue.X;
			else
				_binaryRangeControl.Value = _initialValue.AsFloat2;
			EndInteraction();
		}
		
		void EndInteraction()
		{
			_down = -1;
			_hard = false;
			_control.EndInteraction(this);
			Pointer.ReleaseCapture(this);
		}
		
		double2 _initialValue;
		double _initialAngle, _initialRadius;
		int _down = -1;
		bool _hard;
		
		void OnPointerPressed(object s, PointerPressedArgs args)
		{
			if (_down != -1)
				return;
				
			if (args.TrySoftCapture(this, OnLostCapture))
			{
				Focus.GiveTo(_control);
				_control.BeginInteraction(this, OnLostCapture);
				
				_down = args.PointIndex;
				if (_rangeControl != null)
					_initialValue = new double2(_rangeControl.Value,0);
				else
					_initialValue = new double2(_binaryRangeControl.Value);
					
				_initialAngle = Angle(args);
				_initialRadius = Radius(args);
			}
		}
		
		float2 LocalVector(PointerEventArgs args)
		{
			var l = _control.WindowToLocal(args.WindowPoint);
			var o = l - _control.ActualSize/2;
			return o;
		}
		
		double Radius(PointerEventArgs args)
		{
			return Vector.Length(LocalVector(args));
		}
		
		double Angle(PointerEventArgs args)
		{
			var o = LocalVector(args);
			var a = Math.Atan2(o.Y,o.X);
			if (a < 0)
				a += 2 * Math.PIf;
			return a;
		}
		
		void OnPointerMoved(object s, PointerMovedArgs args)
		{
			if (_down != args.PointIndex)
				return;
				
			var radius = Radius(args);
			var angle = Angle(args);
			if (!_hard && 
				(Math.Abs(angle - _initialAngle) > _angleHardThreshold ||
				Math.Abs(radius - _initialRadius) > _radiusHardThreshold) )
			{
				if (!args.TryHardCapture(this, OnLostCapture))
					OnLostCapture();
				else
					_hard = true;
			}
			
			if (_hard)
				UpdateValue(angle, radius);
		}
		
		void OnPointerReleased(object s, PointerReleasedArgs args)
		{
			if (_down != args.PointIndex)
				return;
				
			UpdateValue(Angle(args), Radius(args));
			EndInteraction();
		}
		
		float2 AngleRange
		{
			get
			{
				var s = _startAngle;
				var e = _endAngle;
				var low = s < e;
				s = Math.Mod(s, 2 * Math.PIf);
				e = Math.Mod(e, 2 * Math.PIf);
				if (low && s > (e - float.ZeroTolerance))
					s -= 2 * Math.PIf;
				else if(!low && s < (e + float.ZeroTolerance))
					s += 2 * Math.PIf;
					
				return float2(s,e);
			}
		}
		
		void UpdateValue(double angle, double radius)
		{
			var step = _rangeControl != null ? float2((float)_rangeControl.RelativeUserStep,0) : 
				_binaryRangeControl.RelativeUserStep;
			var range = AngleRange;
			var rel = Math.Mod(angle - range.X, 2 * Math.PIf) / (range.Y - range.X);
			if (step.X > float.ZeroTolerance)
				rel = Math.Round(rel/step.X) * step.X;
			if (IsWrapping && rel > (1.0f - float.ZeroTolerance))
				rel = 0;
			
			//assume square like Angle
			var relRad = radius / (_control.ActualSize.X / 2);
			var xRad = (relRad - MinimumRadius) / (MaximumRadius - MinimumRadius);
			if (step.Y > float.ZeroTolerance)
				xRad = Math.Round(xRad/step.Y) * step.Y;
			
			ControlRelativeValue = new double2(rel,xRad);
		}
		
		double CurrentRadius
		{
			get
			{
				return (ControlRelativeValue.Y * (MaximumRadius - MinimumRadius) + MinimumRadius) *
					_control.ActualSize.X / 2;
			}
		}
		
		double2 ControlRelativeValue
		{
			get
			{
				if (_rangeControl != null)
					return new double2(_rangeControl.RelativeValue,0);
				else
					return new double2(_binaryRangeControl.RelativeValue);
			}
			set
			{
				if (_rangeControl != null)
					_rangeControl.RelativeValue = value.X;
				else
					_binaryRangeControl.RelativeValue = value.AsFloat2;
			}
		}
		
		//convenience DegreesValue
		[UXOriginSetter("SetDegreesValue")]
		public float DegreesValue
		{
			get 
			{ 	
				var range = AngleRange;
				return (float)Math.RadiansToDegrees(ControlRelativeValue.X * (range.Y - range.X) + range.X);
			}
			set 
			{ 
				UpdateValue(value / 360 * Math.PIf * 2, CurrentRadius);
			}
		}
		
		public void SetDegreesValue(float value, IPropertyListener origin)
		{
			DegreesValue = value;
			//TODO: incomplete for 2-way binding (waiting for better solution)
		}

		static Selector _valueName = "Value";
		static Selector _degreesValueName = "DegreesValue";
		
		public event ValueChangedHandler<float> DegreesValueChanged;
		void OnValueChanged(object s, object args)
		{
			OnPropertyChanged(_valueName);
			OnPropertyChanged(_degreesValueName);
			if (DegreesValueChanged != null)	
				DegreesValueChanged(this, new ValueChangedArgs<float>(DegreesValue));
		}
	}
}
