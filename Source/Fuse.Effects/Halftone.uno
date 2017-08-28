using Uno;
using Uno.Graphics;
using Uno.UX;

using Fuse.Nodes;

namespace Fuse.Effects
{
	/** Applies a classic halftone effect to an @Element.
		@examples Docs/Halftone/Examples.md
	*/
	public sealed class Halftone : BasicEffect
	{
		public Halftone() : base(EffectType.Composition)
		{
		}

		float _spacing = 5;
		/** The amount of space between each dot. */
		public float Spacing
		{
			get { return _spacing; }
			set
			{
				if (_spacing != value)
				{
					_spacing = value;
					OnRenderingChanged();
				}
			}
		}

		float _intensity = 1;
		/** The baseline size of each dot. */
		public float Intensity
		{
			get { return _intensity; }
			set
			{
				if (_intensity != value)
				{
					_intensity = value;
					OnRenderingChanged();
				}
			}
		}

		float _smoothness = 2;
		/** Smoothness of the dot edges. */
		public float Smoothness
		{
			get { return _smoothness; }
			set
			{
				if (_smoothness != value)
				{
					_smoothness = value;
					OnRenderingChanged();
				}
			}
		}

		float _dotTint = 0.5f;
		/** Controls how much the dots should be tinted to the original color of the source @Element. */
		public float DotTint
		{
			get { return _dotTint; }
			set
			{
				if (_dotTint != value)
				{
					_dotTint = value;
					OnRenderingChanged();
				}
			}
		}

		float _paperTint = 0.2f;
		/** Controls how much the background should be tinted to the original color of the source @Element. */
		public float PaperTint
		{
			get { return _paperTint; }
			set
			{
				if (_paperTint != value)
				{
					_paperTint = value;
					OnRenderingChanged();
				}
			}
		}

		protected override void OnRender(DrawContext dc, Rect elementRect)
		{
			var original = Element.CaptureRegion(dc, elementRect, int2(0));
			if (original == null)
				return;

			var tSpacing = Spacing;
			var angle = Math.PIf/4;

			var rot = float2x2( Math.Cos(angle), Math.Sin(angle), -Math.Sin(angle), Math.Cos(angle) );
			var rotI = float2x2( Math.Cos(-angle), Math.Sin(-angle), -Math.Sin(-angle), Math.Cos(-angle) );

			draw Fuse.Drawing.Planar.Image
			{
				DrawContext: dc;
				Visual: Element;
				Position: elementRect.Minimum;
				Invert: true;
				Size: elementRect.Size;
				Texture: original.ColorBuffer;

				//float4 OffColor: float4(TextureColor.XYZ,OffOpacity * TextureColor.W);
				float2 ElementCoord: TexCoord * elementRect.Size + elementRect.Minimum;

				float2 rotTarget: Vector.Transform(ElementCoord,rot);
				float2 rotFloor: (Math.Floor(pixel rotTarget/tSpacing)+0.5f) * tSpacing;
				float2 target: Vector.Transform(rotFloor,rotI);

				//use luminance to determine size
				float3 Primaries: float3(0.299f, 0.587f, 0.114f);
				float Luminance: 1-Vector.Dot(TextureColor.XYZ * TextureColor.XYZ, Primaries);
				float DotSize: (1-Math.Sqrt(Luminance/Math.PIf)) * tSpacing * Intensity;

				float TargetDistance: Vector.Length(ElementCoord-target);
				float EdgeDistance: DotSize - TargetDistance;
				float Sharpness: (1f/Smoothness);
				float Coverage:
					Math.Clamp(0.5f-EdgeDistance*DrawContext.ViewportPixelsPerPoint*Sharpness, 0, 1);

				float4 PaperColor: Math.Lerp(float4(1,1,1,TextureColor.W), TextureColor, PaperTint);
				float4 DotColor: Math.Lerp(float4(0,0,0,TextureColor.W), TextureColor, DotTint);
				PixelColor: Math.Lerp(PaperColor, DotColor, Coverage);
			};

			if defined(FUSELIBS_DEBUG_DRAW_RECTS)
				DrawRectVisualizer.Capture(elementRect.Minimum, elementRect.Size, Element.WorldTransform, dc);

			FramebufferPool.Release(original);
		}
	}
}
