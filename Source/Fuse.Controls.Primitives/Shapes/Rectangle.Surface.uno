using Uno;
using Uno.Collections;

using Fuse.Drawing;

namespace Fuse.Controls
{
	public partial class Rectangle
	{
		protected override bool NeedSurface 
		{ 
			get { return VisualContext != VisualContext.Graphics; }
		}
		
		protected override SurfacePath CreateSurfacePath(Surface surface)
		{
			var rs = ActualSize;
			var useCornerRadius = ConstrainedCornerRadius;
			
			var rect = new List<LineSegment>{
				new LineSegment{ Type = LineSegmentType.Move, To = float2(useCornerRadius[0],0) },
				
				new LineSegment{ Type = LineSegmentType.Straight, 
					To = float2(rs.X - useCornerRadius[1],0) },
				new LineSegment{ Type = LineSegmentType.EllipticArc,
					To = float2(rs.X, useCornerRadius[1]),
					A = float2(useCornerRadius[1]), B = float2(0),
					Flags = LineSegmentFlags.EllipticArcSweep },
					
				new LineSegment{ Type = LineSegmentType.Straight, 
					To = float2(rs.X,rs.Y - useCornerRadius[2]) },
				new LineSegment{ Type = LineSegmentType.EllipticArc,
					To = float2(rs.X-useCornerRadius[2],rs.Y),
					A = float2(useCornerRadius[2]), B = float2(0),
					Flags = LineSegmentFlags.EllipticArcSweep },
				
				new LineSegment{ Type = LineSegmentType.Straight, 
					To = float2(useCornerRadius[3],rs.Y) },
				new LineSegment{ Type = LineSegmentType.EllipticArc,
					To = float2(0,rs.Y-useCornerRadius[3]),
					A = float2(useCornerRadius[3]), B = float2(0),
					Flags = LineSegmentFlags.EllipticArcSweep },
				
				new LineSegment{ Type = LineSegmentType.Straight, 
					To = float2(0,useCornerRadius[0]) },
				new LineSegment{ Type = LineSegmentType.EllipticArc, 
					To = float2(useCornerRadius[0],0),
					A = float2(useCornerRadius[0]), B = float2(0), 
					Flags = LineSegmentFlags.EllipticArcSweep },
					
				new LineSegment{ Type = LineSegmentType.Close },
			};
			
			return surface.CreatePath(rect);
		}
	}
}