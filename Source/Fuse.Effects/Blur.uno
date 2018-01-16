using Uno;
using Uno.Graphics;
using Uno.UX;
using Fuse.Common;
using Fuse.Elements;
using Fuse.Nodes;

namespace Fuse.Effects
{
	/** Applies a gaussian blur to an @Element.
		@examples Docs/Blur/Examples.md
		@remarks Docs/Blur/Remarks.md
	*/
	public sealed class Blur : BasicEffect
	{
		public Blur() :
			base(EffectType.Composition)
		{
			Radius = 3;
		}

		float _radius;
		/** The radius/size of the blur */
		public float Radius
		{
			get { return _radius; }
			set
			{
				if (_radius != value)
				{
					_radius = value;

					OnRenderingChanged();
					OnRenderBoundsChanged();
				}
			}
		}
		
		public override bool Active { get { return Radius > 0; } }

		public override VisualBounds ModifyRenderBounds( VisualBounds inBounds )
		{
			return inBounds.InflateXY(Padding);
		}

		internal float Sigma { get { return Math.Max(Radius, 1e-5f); } }
		internal float Padding { get { return Math.Ceil(Sigma * 3 * Element.AbsoluteZoom) / Element.AbsoluteZoom; } }

		protected override void OnRender(DrawContext dc, Rect elementRect)
		{
			Rect paddedRect = Rect.Inflate(elementRect, Padding);

			// capture stuff
			var original = Element.CaptureRegion(dc, paddedRect, int2(0));
			if (original == null)
				return;

			var blur = EffectHelpers.Instance.Blur(original.ColorBuffer, dc, Sigma * Element.AbsoluteZoom);
			FramebufferPool.Release(original);

			Blitter.Singleton.Blit(blur.ColorBuffer, new Rect(elementRect.Minimum - Padding, paddedRect.Size), dc.GetLocalToClipTransform(Element), 1.0f, true);

			if defined(FUSELIBS_DEBUG_DRAW_RECTS)
				DrawRectVisualizer.Capture(elementRect.Minimum - Padding, paddedRect.Size, Element.WorldTransform, dc);

			FramebufferPool.Release(blur);
		}
	}
}
