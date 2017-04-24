using Uno;
using Uno.UX;

using Fuse.Animations;

namespace Fuse.Triggers
{
	/**
		Animates using a value clamped between a minimum and a maximum as progress.
		
		This is useful when you want to animate something between two arbitrary values.
		
		## Example
		In this example, an @(RangeAnimation) is used to animate a panel 360 degrees as a @(RangeControl2D) goes from 0 to 100.
		
			<RangeControl2D Width="180" Height="180" Margin="2" ux:Name="rangeControl">
				<CircularRangeBehavior/>
				<Panel ux:Name="thumb" Margin="4">
					<Rectangle Color="#fff" Alignment="Right" Height="18" Width="48" CornerRadius="4" />
				</Panel>
				<RangeAnimation Minimum="0" Maximum="100" Value="{ReadProperty rangeControl.ValueX}">
					<Rotate Target="thumb" Degrees="360" />
				</RangeAnimation>
				<Circle Color="#aaa" />
			</RangeControl2D>
		
		@mount Animation
	*/
	public class RangeAnimation : Trigger
	{
		double _value;
		/** The value to be used for animation */
		public float Value
		{
			get { return (float)_value; }
			set
			{
				_value = value;
				if (IsRootingCompleted)
					Update();
			}
		}
		
		float _minimum = 0;
		/** `value`'s minimum value, e.x where progress is 0 */
		public float Minimum 
		{ 
			get { return _minimum; }
			set { _minimum = value; }
		}
		
		float _maximum = 1;
		/** `value`'s maximum value, e.x where progress is 1 */
		public float Maximum 
		{ 
			get { return _maximum; }
			set { _maximum = value; }
		}
		
		double _prevValue;
		protected override void OnRooted()
		{
			base.OnRooted();

			_prevValue = Value;
			BypassSeek(_prevValue);
		}

		void Update()
		{
			var p = Value;
			var diff = p - _prevValue;
			_prevValue = p;

			var relative = Math.Clamp( (p - Minimum) / (Maximum - Minimum), 0, 1);
			Seek(relative, diff >= 0 ? AnimationVariant.Forward : AnimationVariant.Backward);
		}
	}
}

