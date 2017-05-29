using Uno;

using Fuse.Input;
using Fuse.Controls;
using Fuse.Triggers;
using Fuse.Layouts;

namespace Fuse.Gestures
{
	/**
		Common linear sliding behaviour used for implementing a @RangeControl.

		Used to enable sliding touch input on @RangeControl.

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

	*/
	public class LinearRangeBehavior : Behavior, IGesture
	{
		RangeControl FindRangeControl()
		{
			var p = Parent;
			while (p != null && !(p is RangeControl)) p = p.Parent;
			return p as RangeControl;
		}

		RangeControl Control;

		Orientation _orientation = Orientation.Horizontal;
		public Orientation Orientation
		{
			get { return _orientation; }
			set { _orientation = value; }
		}
		
		Gesture _gesture;
		protected override void OnRooted()
		{
			base.OnRooted();

			Control = FindRangeControl();
			if (Control == null)
				Fuse.Diagnostics.UserRootError( "RangeControl", Parent, this );
			else
				_gesture = Input.Gestures.Add( this, Control, GestureType.Primary );
		}

		protected override void OnUnrooted()
		{
			if(_gesture != null)
			{
				_gesture.Dispose();
				_gesture = null;
			}
			Control = null;

			base.OnUnrooted();
		}

		const float _delayStartGesture = 0.0f; //now handled by Gesture system
		static SwipeGestureHelper _horizontalGesture = new SwipeGestureHelper(_delayStartGesture,
			new DegreeSpan(45.0f, 135.0f),	// Right
			new DegreeSpan(-45.0f, -135.0f));	// Left
		static SwipeGestureHelper _verticalGesture = new SwipeGestureHelper(_delayStartGesture,
			new DegreeSpan(-45.0f, 45.0f),
			new DegreeSpan(-135.0f, -180.0f),
			new DegreeSpan( 135.0f,  180.0f));

		SwipeGestureHelper HelpGesture
		{
			get { return Orientation == Orientation.Horizontal ? _horizontalGesture : _verticalGesture; }
		}
		
		void IGesture.OnLostCapture(bool forced)
		{
			if (forced)
				Control.Value = _initialValue;
		}
		
		float IGesture.Significance
		{
			get
			{
				var diff = _currentCoord - _startCoord;
				if (!HelpGesture.IsWithinBounds(_currentCoord - _startCoord))
					return 0;
				
				//TODO: length along axis
				return Vector.Length(_currentCoord - _startCoord);
			}
		}

		GesturePriority IGesture.Priority
		{ get { return GesturePriority.Higher; } }
		
		int IGesture.PriorityAdjustment 
		{ get { return 0; } }
		
		float2 _startCoord;
		float2 _currentCoord;
		double _initialValue = 0f;

		void IGesture.OnCapture(PointerEventArgs args, CaptureType how)
		{
			if (!_gesture.IsHardCapture)
			{
				//TODO: it seems odd to give focus immeidately on SoftCapture, but that is how it worked before.
				Focus.GiveTo(Control);
			}
		}
		
		GestureRequest IGesture.OnPointerPressed(PointerPressedArgs c)
		{
			_startCoord = _currentCoord = c.WindowPoint;
			_initialValue = Control.Value;
			return GestureRequest.Capture;
		}

		GestureRequest IGesture.OnPointerMoved(PointerMovedArgs c)
		{
			_currentCoord = c.WindowPoint;
			if (_gesture.IsHardCapture)
			{
				UpdateValue(Control.WindowToLocal(_currentCoord));
			}
			return GestureRequest.Capture;
		}

		GestureRequest IGesture.OnPointerReleased(PointerReleasedArgs c)
		{
			UpdateValue(Control.WindowToLocal(c.WindowPoint));
			return GestureRequest.Cancel;
		}

		void UpdateValue(float2 pos)
		{
			Control.RelativeValue = PositionToValue(pos);
		}

		double PositionToValue(float2 pos)
		{
			if (Orientation == Orientation.Vertical)
				return pos.Y / Control.ActualSize.Y;
			return pos.X / Control.ActualSize.X;
		}
	}
}
