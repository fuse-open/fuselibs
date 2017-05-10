using Uno;
using Uno.UX;

using Fuse.Drawing;

namespace Fuse.Controls
{
	public abstract partial class EllipticalShape : Shape
	{
		protected SurfacePath CreateEllipticalPath( Surface surface, float2 center, float2 radius,
			bool drawArc = false)
		{
			var list = new LineSegments();
			var startAngle = StartAngle;
			var endAngle = EffectiveEndAngle;
			
			if (UseAngle)
			{
				var s = float2(Math.Cos(startAngle), Math.Sin(startAngle));
				var c = float2(Math.Cos((startAngle+endAngle)/2), Math.Sin((startAngle+endAngle)/2));
				var e = float2(Math.Cos(endAngle), Math.Sin(endAngle));
				
				if (drawArc) 
				{
					list.MoveTo( center + s * radius );
				}
				else
				{
					list.MoveTo( center );
					list.LineTo( center + s * radius );
				}
				
				list.EllipticArcTo( center + c * radius, radius, 0, false, startAngle < endAngle );
				list.EllipticArcTo( center + e * radius, radius, 0, false, startAngle < endAngle );
				
				if (!drawArc)
				{
					list.LineTo( center );
					list.ClosePath();
				}
			}
			else
			{
				list.MoveTo( center + float2(radius.X,0) );
				list.EllipticArcTo( center - float2(radius.X,0), radius, 0, true, true );
				list.EllipticArcTo( center + float2(radius.X,0), radius, 0, true, true );
				list.ClosePath();
			}
			return surface.CreatePath(list.Segments);
		}
	}
}