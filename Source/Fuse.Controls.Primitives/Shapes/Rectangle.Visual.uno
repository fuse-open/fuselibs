using Uno;
using Uno.UX;

using Fuse.Drawing;

namespace Fuse.Controls
{
	public partial class Rectangle
	{
		protected override void DrawFill(DrawContext dc, Brush fill)
		{
			Fuse.Drawing.Primitives.Rectangle.Singleton.Fill(dc,this,
				ActualSize, CornerRadius, fill, float2(0), Smoothness);
		}
		
		protected override void DrawStroke(DrawContext dc, Stroke stroke)
		{
			Fuse.Drawing.Primitives.Rectangle.Singleton.Stroke(dc,this,
				ActualSize, CornerRadius, stroke, float2(0), Smoothness);
		}

		protected override void OnHitTestLocalVisual(Fuse.HitTestContext htc)
		{
			base.OnHitTestLocalVisual(htc);
			
			var lp = htc.LocalPoint;
			if (!HasFills || !IsPointInside(lp))
				return;

			var cr = ConstrainedCornerRadius;
				
			if (lp.X < cr[0] && lp.Y < cr[0])
			{
				if( Vector.Distance( lp, float2(cr[0] ) ) > cr[0] )
					return;
			}
			else if (lp.X > (ActualSize.X - cr[1]) && lp.Y < cr[1])
			{
				if( Vector.Distance( lp, float2(ActualSize.X - cr[1], cr[1] ) ) 
					> cr[1] )
					return;
			}
			else if (lp.X < cr[3] && lp.Y > (ActualSize.Y - cr[3]))
			{
				if( Vector.Distance( lp, float2(cr[3],ActualSize.Y - cr[3]) )
					> cr[3] )
					return;
			}
			else if (lp.X > (ActualSize.X - cr[2]) && lp.Y > (ActualSize.Y - cr[2]) )
			{
				if( Vector.Distance( lp, float2(ActualSize.X - cr[2], 
					ActualSize.Y - cr[2] ) ) > cr[2] )
					return;
			}
			
			htc.Hit(this);
		}
	}
}
