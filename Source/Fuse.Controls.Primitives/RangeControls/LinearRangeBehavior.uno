using Uno;

using Fuse.Input;
using Fuse.Controls;
using Fuse.Elements;
using Fuse.Triggers;
using Fuse.Layouts;

namespace Fuse.Gestures
{
	/**
		Common linear sliding behaviour used for implementing a @RangeControl.

		Used to enable sliding touch input on @RangeControl.
		
		The range of motion of the control is the size of the `LinearRangeBehavior` parent. By nesting deeper than the immediate child of the @RangeControl you can have a range of motion distinct from the size of the overall control.

		## Example

			<StackPanel>

				<RangeControl ux:Class="CustomSlider" Padding="16,2,16,2" Margin="2" >
					<Panel>
						<LinearRangeBehavior />
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
		
		Element _boundsElement;
		Gesture _gesture;
		protected override void OnRooted()
		{
			base.OnRooted();

			Control = FindRangeControl();
			if (Control == null)
				Fuse.Diagnostics.UserRootError( "RangeControl", Parent, this );
			
			_boundsElement = Parent as Element;
			if (_boundsElement == null)
				Fuse.Diagnostics.UserRootError( "Element", Parent, this );
			else
				_gesture = Input.Gestures.Add( this, _boundsElement, GestureType.Primary );
		}

		protected override void OnUnrooted()
		{
			if(_gesture != null)
			{
				_gesture.Dispose();
				_gesture = null;
			}
			Control = null;
			_boundsElement = null;

			base.OnUnrooted();
		}

		float2 Direction
		{
			get { return Orientation == Orientation.Horizontal ? float2(1,0) : float2(0,1); }
		}
		
		void IGesture.OnLostCapture(bool forced)
		{
			if (forced)
				Control.Value = _initialValue;
		}
		
		GesturePriority _gesturePriority = GesturePriority.Normal;
		/** Alters the priority of the gesture relative to other gestures. */
		public GesturePriority GesturePriority
		{
			get { return _gesturePriority; }
			set { _gesturePriority = value; }
		}

		GesturePriorityConfig IGesture.Priority
		{
			get 
			{
				return new GesturePriorityConfig( GesturePriority.Normal,
					Gesture.VectorSignificance( Direction, _currentCoord - _startCoord ) );
			}
		}
		
		float2 _startCoord;
		float2 _currentCoord;
		double _initialValue = 0f;

		void IGesture.OnCaptureChanged(PointerEventArgs args, CaptureType how, CaptureType prev)
		{
			if (_gesture.IsHardCapture)
				Focus.GiveTo(Control);
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
				UpdateValue(_boundsElement.WindowToLocal(_currentCoord));
			}
			return GestureRequest.Capture;
		}

		GestureRequest IGesture.OnPointerReleased(PointerReleasedArgs c)
		{
			UpdateValue(_boundsElement.WindowToLocal(c.WindowPoint));
			return GestureRequest.Cancel;
		}

		void UpdateValue(float2 pos)
		{
			var step = Control.RelativeUserStep;
			var r = PositionToValue(pos);
			var q = step > 0 ? Math.Round(r/step) * step : r;
			Control.RelativeValue = Math.Clamp(q,0,1);
		}

		double PositionToValue(float2 pos)
		{
			if (Orientation == Orientation.Vertical)
				return pos.Y / _boundsElement.ActualSize.Y;
			return pos.X / _boundsElement.ActualSize.X;
		}
	}
}
