using Uno;
using Uno.Collections;

namespace Fuse.Layouts
{
	/**	Lays out elements in an a circular way.

		@CircleLayout must be placed inside a @Panel, and will apply to the elements inside it.

		We can use `StartAngleDegrees` and `EndAngleDegrees` to define how much of the circle will
		be covered. Here zero degrees equals 3 o'clock.

		> Note that `EndAngleDegrees` should be greater than `StartAngleDegrees` to avoid
		> layout calculation issues.

		## Example

			<Panel Color="#000000">
				<CircleLayout />
				<Circle Fill="#ff00ff" />
				<Circle Fill="#7f7fff" />
				<Circle Fill="#00ffff" />
				<Circle Fill="#7fff7f" />
				<Circle Fill="#ffff00" />
				<Circle Fill="#ff7f7f" />
			</Panel>

		The layout calculation is done by fitting circles into a large circle. The elements inside are all
		treated as circles, such that arranging them they all just touch the `Radius` edge and each other
		(with a zero arc-spacing).
	*/
	public class CircleLayout : Layout
	{
		float _radius = 1;
		/**	Radius of bounding circle.
		*/
		public float Radius
		{
			get { return _radius; }
			set
			{
				_radius = value;
				InvalidateLayout();
			}
		}

		float _itemSpacing = 0;
		/**	Spacing between each element on the circle in degrees.

			This value should be set to less than the arc length in degrees divided by
			the number of elements
		*/
		public float ItemSpacingDegrees
		{
			get { return Math.RadiansToDegrees(_itemSpacing); }
			set
			{
				_itemSpacing = Math.DegreesToRadians(value);
				InvalidateLayout();
			}
		}

		float _startAngle = 0;
		/**	The angle where the circle segment starts.
		
			This is the point on the circle where the first element will be centered.

			@default 0

			> Note: Zero degrees translates to 3'o clock, and rotation will be clockwise.
		*/
		public float StartAngleDegrees
		{
			get { return Math.RadiansToDegrees(_startAngle); }
			set
			{
				_startAngle = Math.DegreesToRadians(value);
				InvalidateLayout();
			}
		}

		float _endAngle = Math.PIf * 2;
		/**	The angle where the circle segment ends.

			@default 360

			> Note that `EndAngleDegrees` should be greater than `StartAngleDegrees` to avoid
			> layout calculation issues.
		*/
		public float EndAngleDegrees
		{
			get { return Math.RadiansToDegrees(_endAngle); }
			set
			{
				_endAngle = Math.DegreesToRadians(value);
				InvalidateLayout();
			}
		}

		internal override float2 GetContentSize(Visual container, LayoutParams lp)
		{
			//TODO: something sensible?
			return float2(0);
		}

		/*
			The layout calculation is done based on fitting circles into a large circle. The provided lp.Size is
			taken as the fitting area, and Radius indicates the outer edge. The elements inside are treated
			all as circles, such that arranging them they all just touch the Radius edge and each other (with
			a zero arc-spacing).
		*/
		internal override void ArrangePaddingBox(Visual container, float4 padding, LayoutParams lp)
		{
			var nlp = lp.CloneAndDerive();
			nlp.RemoveSize(padding);

			int c = 0;
			for (var e = container.FirstChild<Visual>(); e != null; e = e.NextSibling<Visual>())
			{
				if (ArrangeMarginBoxSpecial(e, padding, lp))
					continue;
				c++;
			}

			var angleRange = _endAngle - _startAngle;
			var step = angleRange / c;
			var arcSize = (step - _itemSpacing) / 2;
			var fitRadius = Radius * Math.Sin(arcSize) / (Math.Sin(arcSize) + 1);
			var elementRadius = nlp.Size/2 * (Radius - fitRadius);
			var elementSize = nlp.Size * fitRadius;
			var angle = _startAngle;
			nlp.SetSize(elementSize);

			for (var e = container.FirstChild<Visual>(); e != null; e = e.NextSibling<Visual>())
			{
				if (!AffectsLayout(e))
					continue;

				var x = Math.Cos(angle) * elementRadius.X + lp.Size.X/2;
				var y = Math.Sin(angle) * elementRadius.Y + lp.Size.Y/2;
				var p = padding.XY + float2(x,y) - elementSize/2;
				e.ArrangeMarginBox( p, nlp);
				angle += step;
			}
		}
	}
}
