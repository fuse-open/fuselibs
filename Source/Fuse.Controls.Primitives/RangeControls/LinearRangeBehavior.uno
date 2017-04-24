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
	public class LinearRangeBehavior : Behavior
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
		
		protected override void OnRooted()
		{
			base.OnRooted();

			Control = FindRangeControl();
			if (Control == null)
				Fuse.Diagnostics.UserRootError( "RangeControl", Parent, this );

			Pointer.AddHandlers(Control, OnPointerPressed, OnPointerMoved, OnPointerReleased);
		}

		protected override void OnUnrooted()
		{
			if(Control != null)
				Pointer.RemoveHandlers(Control, OnPointerPressed, OnPointerMoved, OnPointerReleased);
			Control = null;

			base.OnUnrooted();
		}

		const float _delayStartGesture = 10.0f;
		static SwipeGestureHelper _horizontalGesture = new SwipeGestureHelper(_delayStartGesture,
			new DegreeSpan(45.0f, 135.0f),	// Right
			new DegreeSpan(-45.0f, -135.0f));	// Left
		static SwipeGestureHelper _verticalGesture = new SwipeGestureHelper(_delayStartGesture,
			new DegreeSpan(-45.0f, 45.0f),
			new DegreeSpan(-135.0f, -180.0f),
			new DegreeSpan( 135.0f,  180.0f));

		SwipeGestureHelper Gesture
		{
			get { return Orientation == Orientation.Horizontal ? _horizontalGesture : _verticalGesture; }
		}
		
		void OnLostCapture()
		{
			_down = -1;
			Control.Value = _initialValue;
			Control.EndInteraction(this);
		}

		float2 _startCoord = float2(0f);
		double _initialValue = 0f;
		int _down = -1;

		void OnPointerPressed(object sender, PointerPressedArgs c)
		{
			if (_down == -1)
			{
				if (c.TrySoftCapture(this, OnLostCapture))
				{
					Focus.GiveTo(Control);
					Control.BeginInteraction(this, OnLostCapture);

					_startCoord = c.WindowPoint;
					_down = c.PointIndex;
					_initialValue = Control.Value;
				}
			}
		}

		void OnPointerMoved(object sender, PointerMovedArgs c)
		{
			if (_down != c.PointIndex)
				return;

			if (c.IsSoftCapturedTo(this))
			{
				if (Gesture.IsWithinBounds(c.WindowPoint - _startCoord))
					c.TryHardCapture(this, OnLostCapture);
			}
			else if (c.IsHardCapturedTo(this))
			{
				UpdateValue(Control.WindowToLocal(c.WindowPoint));
			}
		}

		void OnPointerReleased(object sender, PointerReleasedArgs c)
		{
			if (_down != c.PointIndex)
				return;

			if (c.IsCapturedTo(this))
			{
				UpdateValue(Control.WindowToLocal(c.WindowPoint));
				c.ReleaseCapture(this);
			}
			Control.EndInteraction(this);
			_down = -1;
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
