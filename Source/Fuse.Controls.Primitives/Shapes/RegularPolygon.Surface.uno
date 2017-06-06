using Uno;
using Uno.Collections;

using Fuse.Drawing;

namespace Fuse.Controls
{
	public partial class RegularPolygon
	{
		protected override SurfacePath CreateSurfacePath(Surface surface)
		{
			var radius = Math.Min(ActualSize.X, ActualSize.Y) * 0.5f;
			var center = ActualSize / 2;
			var list = new List<LineSegment>();

			if (Sides >= 3)
			{
				var t = -2 * Math.PIf / Sides;
				list.Add( new LineSegment{ Type = LineSegmentType.Move, 
					To = float2(center.X, center.Y - radius) } );
				
				for (int i = 1; i<Sides; i++)
				{
					list.Add( new LineSegment{ Type = LineSegmentType.Straight, To = float2(
						center.X + Math.Sin(t*i) * radius,
						center.Y - Math.Cos(t*i) * radius) });
				}
				
				list.Add( new LineSegment{ Type = LineSegmentType.Close } );
			}
			
			return surface.CreatePath(list);
		}
	}
}
