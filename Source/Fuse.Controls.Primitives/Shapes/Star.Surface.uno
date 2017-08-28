using Uno;
using Uno.Collections;

using Fuse.Drawing;

namespace Fuse.Controls
{
	public partial class Star
	{
		protected override SurfacePath CreateSurfacePath(Surface surface)
		{
			var list = new List<LineSegment>();
			if (Points < 3) 
				return surface.CreatePath(list);

			var t = -2 * Math.PIf / (Points * 2);
			var center = ActualSize / 2;
			var radius = Math.Min(ActualSize.X, ActualSize.Y) * 0.5f;
			var spokeRadius = radius * Ratio;
			var rotation = RotationRadians;
			var cornerRatio = RoundRatio;
			
			var count = Points * 2;
			for (int i = 0; i < count; i++)
			{
				float2 segRadius = i%2==0 ? float2(radius,spokeRadius) : float2(spokeRadius,radius);
				
				var pa = float2(center.X + Math.Sin(t*i + rotation) * segRadius[0], 
					center.Y - Math.Cos(t*i + rotation) * segRadius[0] );
				var pb = float2(center.X + Math.Sin(t*(i+1) + rotation) * segRadius[1], 
					center.Y - Math.Cos(t*(i+1) + rotation) * segRadius[1] );

				if (i==0)
					list.Add( new LineSegment{ Type = LineSegmentType.Move, To = pa } );

				const float zeroTolerance = 1e-05f;
				if (cornerRatio > zeroTolerance)
				{
					var na = float2(Math.Cos(t*i + rotation), Math.Sin(t*i + rotation));
					var nb = float2(Math.Cos(t*(i+1) + rotation), Math.Sin(t*(i+1) + rotation));
				
					list.Add( new LineSegment{ Type = LineSegmentType.BezierCurve, To = pb,
						A = pa - na * cornerRatio * segRadius[0],
						B = pb + nb * cornerRatio * segRadius[1] } );
				}
				else
				{
					list.Add( new LineSegment{ Type = LineSegmentType.Straight, To = pb } );
				}
			}
			list.Add(new LineSegment{ Type = LineSegmentType.Close });
			return Surface.CreatePath(list);
		}
	}
}
