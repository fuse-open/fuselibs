using Uno;
using Uno.UX;

using Fuse.Drawing;

namespace Fuse.Controls
{
	public partial class Circle
	{
		protected float2 Center
		{
			get { return ActualSize/2; }
		}

		float2 CanvasAngles
		{
			get
			{
				var s = StartAngle;
				var e = EffectiveEndAngle;
				if (e < s)
					return float2(e,s);
				return float2(s,e);
			}
		}
		
		protected override void DrawFill(DrawContext dc, Brush fill)
		{
			var angles = CanvasAngles;
			
			if (UseAngle)
				Fuse.Drawing.Primitives.Wedge.Singleton.Fill(dc,this,Radius,fill,Center,
					angles[0], angles[1], Smoothness);
			else
				Fuse.Drawing.Primitives.Circle.Singleton.Fill(dc,this,Radius,fill,Center, 
					Smoothness);
		}
		
		protected override void DrawStroke(DrawContext dc, Stroke stroke)
		{
			var angles = CanvasAngles;
			
			if (UseAngle)
				Fuse.Drawing.Primitives.Wedge.Singleton.Stroke(dc,this,Radius,stroke, Center,
					angles[0], angles[1], Smoothness);
			else
				Fuse.Drawing.Primitives.Circle.Singleton.Stroke(dc,this,Radius,stroke, Center,
					Smoothness);
		}

		protected override void OnHitTestLocalVisual(Fuse.HitTestContext htc)
		{
			base.OnHitTestLocalVisual(htc);
			
			if (!HasFills || Vector.Distance(htc.LocalPoint, Center) > Radius)
				return;
			
			if (UseAngle)
			{
				var off = htc.LocalPoint - Center;
				var localAngle = Math.Atan2(off.Y,off.X);
				if (!SurfaceUtil.AngleInRange(localAngle, StartAngle, EffectiveEndAngle))
					return;
			}
			
			htc.Hit(this);
		}
	}
}