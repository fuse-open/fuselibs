using Uno;
using Uno.Graphics;
using Uno.UX;

using Fuse.Nodes;

namespace Fuse.Effects
{

	/** Applies a duotone effect to an @Element.
		@examples Docs/Duotone/Examples.md
	*/
	public class Duotone : BasicEffect
	{
		public Duotone() : base(EffectType.Composition)
		{
		}


		float _amount = 1;
		/**
			Allows mixing between the original color and the one applied by the effect.
			When `1`, the duotone effect is completely applied.
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

		float3 _light = float3(1.0f,1.0f,1.0f);
		/**
		   The color of the light parts of the element.
		*/
		public float3 Light
		{
			get { return _light; }
			set
			{
				if (_light != value)
				{
					_light = value;
					OnRenderingChanged();
				}
			}
		}

		float3 _shadow = float3(0.0f, 0.0f, 0.0f);
		/**
		   The color of the dark parts of the element.
		*/
		public float3 Shadow
		{
			get { return _shadow; }
			set
			{
				if (_shadow != value)
				{
					_shadow = value;
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

				PixelColor : float4(Math.Lerp(TextureColor.XYZ, Math.Lerp(_shadow, _light, Luminance).XYZ, Amount), TextureColor.W);
			};

			if defined(FUSELIBS_DEBUG_DRAW_RECTS)
				DrawRectVisualizer.Capture(elementRect.Minimum, elementRect.Size, Element.WorldTransform, dc);

			FramebufferPool.Release(original);
		}
	}
}
