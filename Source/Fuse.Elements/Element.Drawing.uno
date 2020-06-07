using Uno;
using Uno.Graphics;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Elements
{

	public abstract partial class Element
	{
		public const CachingMode DefaultCachingMode = CachingMode.Optimized;

		/**
			How the element's visuals are cached while drawing.

			You generally don't need to modify this as the default uses a heuristical approach to determine what it should and should not cache. Modifying this incorrectly could result in worse performance.
		*/
		public CachingMode CachingMode
		{
			get { return Get(FastProperty1.CachingMode, DefaultCachingMode); }
			set
			{
				if (CachingMode != value)
				{
					Set(FastProperty1.CachingMode, value, DefaultCachingMode);
					InvalidateVisual();
				}
			}
		}

		public framebuffer CaptureRegion(DrawContext dc, Rect region, float2 padding)
		{
			var sz = region.Size + padding * 2;

			var pixelSize = Math.Ceil(sz * AbsoluteZoom);
			var fsz = int2((int)pixelSize.X,(int)pixelSize.Y);
			if (fsz.X > texture2D.MaxSize ||
			    fsz.Y > texture2D.MaxSize)
			{
				debug_log "CaptureRegion bigger than maximum texture size, dropping rendering (size: " +
					fsz + ", max-size: " + texture2D.MaxSize;
				return null;
			}
			var fb = FramebufferPool.Lock( fsz, Uno.Graphics.Format.RGBA8888, false);
			var cc = new OrthographicFrustum{
				Origin = float2(region.Left - padding.X, region.Top - padding.Y),
				Size = sz,
				LocalFromWorld = WorldTransformInverse };

			dc.PushRenderTargetFrustum(fb,cc);
			dc.Clear(float4(0), 1);
			//dc.PushScissor( new Recti(0, 0, fsz.X, fsz.Y));

			DrawWithChildren(dc);

			dc.PopRenderTargetFrustum();

			return fb;
		}

		extern (FUSELIBS_PROFILING) double _childCullTime;


		public override void Draw(DrawContext dc)
		{
			if (!IsRootingCompleted)
				Fuse.Diagnostics.InternalError( "Draw called on a non-rooted node", this );

			if (Visibility != Visibility.Visible)
				return;

			extern double cullTime;
			if defined (FUSELIBS_PROFILING)
				cullTime = Uno.Diagnostics.Clock.GetSeconds();

			var visibleRect = GetVisibleViewportInvertPixelRect(dc, RenderBoundsWithEffects);

			if defined (FUSELIBS_PROFILING)
			{
				var pe = Parent as Element;
				if (pe != null)
				{
					cullTime = Uno.Diagnostics.Clock.GetSeconds() - cullTime;
					pe._childCullTime += cullTime;
				}
				_childCullTime = 0;
			}

			if (visibleRect.Size.X == 0 || visibleRect.Size.Y == 0)
				return;

			extern double t;
			if defined(FUSELIBS_PROFILING)
			{
				t = Uno.Diagnostics.Clock.GetSeconds();
				Fuse.Profiling.BeginRegion(this.ToString());
				_childCullTime = 0;
			}

			if (NeedsClipping)
			{
				//TODO: This doesn't work if element is transformed!
				dc.PushScissor(visibleRect);
				Composit(dc);
				dc.PopScissor();
			}
			else
			{
				Composit(dc);
			}

			if defined(FUSELIBS_PROFILING)
			{
				if (_childCullTime > 0)
					Fuse.Profiling.LogEvent("Culling of children", _childCullTime);
				Fuse.Profiling.EndRegion(Uno.Diagnostics.Clock.GetSeconds() - t);
			}
		}
	}
}
