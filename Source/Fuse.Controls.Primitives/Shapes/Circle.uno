using Uno;
using Uno.UX;

using Fuse.Elements;
using Fuse.Drawing;

namespace Fuse.Controls
{
	/** Displays a circle

		Circle is a @Shape that can have @Fills and @Strokes.
		By default Circle does not have a size, fills or strokes. You must add some for it
		to become visible.

		### StartAngle / EndAngle

		`StartAngle` and `EndAngle` can be used to only draw a slice of a @Circle.
		There are 6 different properties that can be used to control this in different ways.

		* `StartAngle` - The angle in radians where the slice begins
		* `StartAngleDegrees` - The angle in degrees where the slice begins
		* `EndAngle` - The angle in radians where the slice ends
		* `EndAngleDegrees` - The angle in degrees where the slice ends
		* `LengthAngle` - An offset in radians from `StartAngle`. This can be used instead of `EndAngle`
		* `LengthAngleDegrees` - An offset in degrees from `StartAngle`. This can be used instead of `EndAngleDegrees`.

		Note that using for example both @(StartAngle) and @(StartAngleDegrees) on the same @(Circle) will have an undefined behavior.

		## Examples
		
		Displaying a red @Circle:
		
		```
		<Circle Width="100" Height="100" Color="#f00" />
		```
		
		Getting fancy with a @Stroke and @LinearGradient:
		
		```
		<Circle Width="100" Height="100" >
			<LinearGradient>
				<GradientStop Offset="0" Color="#cf0" />
				<GradientStop Offset="1" Color="#f40" />
			</LinearGradient>
			<Stroke Width="1">
				<SolidColor Color="#000" />
			</Stroke>
		</Circle>
		```
		
		Drawing a slice of a circle:
		
		```
		<Circle Width="150" Height="150" Color="#f00" StartAngleDegrees="135" LengthAngleDegrees="145" />
		```
	*/
	public partial class Circle : EllipticalShape
	{
		internal float Radius
		{
			get
			{
				return Math.Min(ActualSize.X, ActualSize.Y) * 0.5f;
			}
		}

		protected override bool NeedSurface
		{
			get { return VisualContext != VisualContext.Graphics; }
		}
		
		protected override SurfacePath CreateSurfacePath(Surface surface)
		{
			return CreateEllipticalPath( surface, Center, float2(Radius) );
		}
	}
}
