using Uno;
using Uno.UX;

namespace Fuse.Elements
{
	public abstract partial class Element
	{
		protected VisualBounds CalcRenderBoundsWithEffects()
		{
			var r = RenderBoundsWithoutEffects;
			if (HasActiveEffects)
			{
				for (int i = 0; i < Effects.Count; i++) // js optimization
				{
					var e = Effects[i];
					if (e.Active)
						r = e.ModifyRenderBounds(r);
				}
			}
			return r;
		}

		VisualBounds _renderBoundsWithEffects;
		public VisualBounds RenderBoundsWithEffects
		{
			get
			{
				if (_renderBoundsWithEffects == null)
				{
					_renderBoundsWithEffects = CalcRenderBoundsWithEffects();
				}

				return _renderBoundsWithEffects;
			}
		}

		bool NeedsClipping
		{
			get { return ClipToBounds; }
		}

		VisualBounds _renderBoundsWithoutEffects;
		public VisualBounds RenderBoundsWithoutEffects
		{
			get
			{
				if (_renderBoundsWithoutEffects == null)
				{
					_renderBoundsWithoutEffects = CalcRenderBounds();
					if (ClipToBounds)
					{
						_renderBoundsWithoutEffects = _renderBoundsWithoutEffects.IntersectXY(
							VisualBounds.Rect(float2(0),ActualSize) );
					}
				}
				return _renderBoundsWithoutEffects;
			}
		}

		protected virtual VisualBounds CalcRenderBounds()
		{
			return VisualBounds.Merge(VisualChildren, VisualBounds.Type.Render);
		}

		//how much of a pixel must be covered by a virtual pixel/bound to be considered as covering that pixel
		//otherwise Floor/Ceil could round incorrectly on near exact values due to precision
		//refer to: https://github.com/fusetools/fuselibs/issues/735
		const float pixelEpsilon = 0.005f;
		
		internal Recti GetViewportInvertPixelRect(DrawContext dc, Rect localRegion)
		{
			var transformMatrix = dc.GetLocalToClipTransform(this);
			var esr = Rect.Transform(localRegion, transformMatrix);
			
			var low = Math.Floor( pixelEpsilon +
				(Math.Min( esr.Minimum, esr.Maximum )+1f)/2f * dc.GLViewportPixelSize 
				);
			var high = Math.Ceil( (Math.Max( esr.Minimum, esr.Maximum )+1f)/2f * dc.GLViewportPixelSize -
				pixelEpsilon
				);
			var r  = new Recti( (int)low.X, (int)(dc.GLViewportPixelSize.Y-high.Y), 
				(int)(high.X), (int)(dc.GLViewportPixelSize.Y - low.Y) );
			return r;
		}

		public Recti GetVisibleViewportInvertPixelRect(DrawContext dc, VisualBounds localRegion)
		{
			if (localRegion.IsInfinite)
				return dc.Scissor;
			if (localRegion.IsEmpty)
				return new Recti(0,0,0,0);
				
			var s = dc.Scissor;
			var v = GetViewportInvertPixelRect(dc, localRegion.FlatRect);
			var i = Recti.Intersect(s,v);
			if (i.Size.X < 0 || i.Size.Y < 0)
				return new Recti(0,0,0,0);
			return i;
		}

		/**
			Derived classes can override CalcRenderBounds() which should be the local visual
			render bounds. The effects will be added to that.
		*/
		public override VisualBounds LocalRenderBounds
		{
			get { return RenderBoundsWithEffects; }
		}
	}
}
