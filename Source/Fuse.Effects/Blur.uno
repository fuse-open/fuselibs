using Uno;
using Uno.Graphics;
using Uno.UX;
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

			draw Fuse.Drawing.Planar.Image
			{
				DrawContext: dc;
				Visual: Element;
				Position: elementRect.Minimum - Padding;
				Invert: true;
				Size: paddedRect.Size;
				Texture: blur.ColorBuffer;

				apply Fuse.Drawing.PreMultipliedAlphaCompositing;
				DepthTestEnabled: false;
			};

			if (defined(FUSELIBS_DEBUG_DRAW_RECTS) && dc.RenderTarget == DrawRectVisualizer.RenderTarget)
			{
				float2[] drawRectInputVerts = new[]
				{
					float2(0, 0),
					float2(1, 0),
					float2(1, 1),
					float2(0, 1)
				};
				float4[] drawRectWorldSpaceVerts = new[]
				{
					float4(0),
					float4(0),
					float4(0),
					float4(0)
				};
				float2 drawRectPos = paddedRect.Minimum / dc.ViewportPixelsPerPoint;
				float2 drawRectSize = paddedRect.Size / dc.ViewportPixelsPerPoint;
				for(int i = 0; i < 4; i++)
				{
					var coord = drawRectInputVerts[i];
					var p = Vector.Transform(float4(drawRectPos + coord * drawRectSize, 0, 1), Element.WorldTransform);
					drawRectWorldSpaceVerts[i] = p;
				}
				DrawRectVisualizer.Append(new DrawRect(drawRectWorldSpaceVerts, dc.Scissor));
			}

			FramebufferPool.Release(blur);
		}
	}
}
