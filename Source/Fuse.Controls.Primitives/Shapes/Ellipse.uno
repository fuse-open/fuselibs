using Uno;
using Uno.UX;

using Fuse.Drawing;

namespace Fuse.Controls
{
	/** Displays an ellipse

		Ellipse is a @Shape that can have @Fills and @Strokes.
		By default Ellipse does not have a size, fills or strokes. You must add some for it
		to become visible.

		## Example:

			<Ellipse Width="300" Height="100">
				<LinearGradient>
					<GradientStop Offset="0" Color="#0cc" />
					<GradientStop Offset="1" Color="#cc0" />
				</LinearGradient>
				<Stroke Width="1">
					<SolidColor Color="#000" />
				</Stroke>
			</Ellipse>

	*/
	public partial class Ellipse : EllipticalShape
	{
		protected override SurfacePath CreateSurfacePath(Surface surface)
		{
			return CreateEllipticalPath( surface, ActualSize/2, ActualSize/2 );
		}
		
		protected override void OnHitTestLocalVisual(Fuse.HitTestContext htc)
		{
			base.OnHitTestLocalVisual(htc);
			
			if (!HasFills)
				return;
				
			const float pointsZeroTolerance = 1e-05f;
			if (ActualSize.Y < pointsZeroTolerance || ActualSize.X < pointsZeroTolerance)
				return;
			//normalized point offset from center of control
			var offPoint = (htc.LocalPoint - ActualSize/2) / (ActualSize/2);
			
			if (Vector.Length(offPoint) > 1)
				return;
			
			if (UseAngle)
			{
				var localAngle = Math.Atan2(offPoint.Y,offPoint.X);
				if (!SurfaceUtil.AngleInRange(localAngle, StartAngle, EffectiveEndAngle))
					return;
			}
			
			htc.Hit(this);
		}
	}
}
