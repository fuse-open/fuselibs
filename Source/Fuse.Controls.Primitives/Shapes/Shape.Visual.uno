using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse.Drawing;
using Fuse.Elements;

namespace Fuse.Controls
{
	public abstract partial class Shape
	{
		protected override bool FastTrackDrawWithOpacity(DrawContext dc)
		{
			return false;
		}
		
		protected override void DrawVisual(DrawContext dc)
		{ 
			if (_surface != null)
			{
				_surface.Draw(dc, this, this);
				return;
			}
			
			PrepareDraw(dc, ActualSize);
			
			if (HasFills)
			{
				foreach (var fill in Fills)
					DrawFill(dc, fill);
			}
			
			if (HasStrokes)
			{
				foreach (var stroke in Strokes)
					DrawStroke(dc, stroke);
			}
		}
		
		protected virtual void DrawFill(DrawContext dc, Brush fill) { }
		protected virtual void DrawStroke(DrawContext dc, Stroke stroke) { }
		
		protected override VisualBounds HitTestLocalVisualBounds
		{
			get
			{
				var b = base.HitTestLocalVisualBounds;
				b = b.AddRect( float2(0), ActualSize );
				return b;
			}
		}

		/**
			Override `CalcShapeExtents` to provide custom bounds for a shape. This function will then add the appropriate padding for the strokes.
		*/
		protected sealed override VisualBounds CalcRenderBounds()
		{
			var r = base.CalcRenderBounds();
			if (!(HasStrokes || HasFills))
				return r;
				
			var extents = CalcShapeExtents();
				
			float adjust = 0;
			if (HasStrokes)
			{
				foreach (var stroke in Strokes)
				{
					var extent = stroke.GetDeviceAdjusted( Viewport.PixelsPerPoint );
					
					//extends for worst case Square caps and miter limit/bevels
					var m = extent[1] + Math.Max( extent[0] * Stroke.LineJoinMiterLimit,
						Vector.Length(float2(extent[0])) );
					adjust = Math.Max(adjust, m);
				}
			}
			adjust += Smoothness-1;
			
			extents.Minimum -= adjust;
			extents.Maximum += adjust;
			r = r.AddRect(extents);
			return r;
		}

		virtual protected Rect CalcShapeExtents()
		{
			return new Rect(float2(0),ActualSize);
		}
	}
}
