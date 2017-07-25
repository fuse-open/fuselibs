using Uno;
using Uno.Graphics;
using Uno.UX;
using Fuse.Nodes;

namespace Fuse.Effects
{
	/** Desaturates an @Element.
		@examples Docs/Desaturate/Examples.md
	*/
	public sealed class Desaturate : BasicEffect
	{
		public Desaturate() : base(EffectType.Composition)
		{
		}

		float _amount = 1;
		/**
			The amount of desaturation to apply.
			When `1`, the @Element will be completely grayscale.
		*/
		public float Amount
		{
			get { return _amount; }
			set
			{
				if (_amount != value)
				{
					_amount = value;
					OnRenderingChanged();
				}
			}
		}

		protected override void OnRender(DrawContext dc, Rect elementRect)
		{
			var original = Element.CaptureRegion(dc, elementRect, int2(0));
			if (original == null)
				return;

			draw Fuse.Drawing.Planar.Image
			{
				DrawContext: dc;
				Visual: Element;
				Position: elementRect.Minimum;
				Invert: true;
				Size: elementRect.Size;
				Texture: original.ColorBuffer;
				TextureColor: float4(prev TextureColor.XYZ / Math.Max(prev TextureColor.W, 1e-5f), prev TextureColor.W);
				float3 Primaries: float3(0.299f, 0.587f, 0.114f); // CCIR 601
				float Luminance: Math.Sqrt(Vector.Dot(TextureColor.XYZ * TextureColor.XYZ, Primaries)); // HSP Color Model
				PixelColor: float4(Math.Lerp(TextureColor.XYZ, float3(Luminance), Amount), TextureColor.W);
			};

			if defined(FUSELIBS_DEBUG_DRAW_RECTS)
				DrawRectVisualizer.Capture(elementRect.Minimum, elementRect.Size, Element.WorldTransform, dc);

			FramebufferPool.Release(original);
		}
	}
}
