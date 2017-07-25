using Uno;
using Uno.UX;
using Fuse.Elements;
using Fuse.Nodes;

namespace Fuse.Effects
{
	/** DropShadow applies an underlying shadow to an @Element.
		@examples Docs/DropShadow/Examples.md
	*/
	public class DropShadow : BasicEffect
	{
		float _size;
		/** The size of the shadow, in points. */
		public float Size
		{
			get { return _size; }
			set
			{
				if (_size != value)
				{
					_size = value;

					if (Active)
					{
						OnRenderingChanged();
						OnRenderBoundsChanged();
					}
				}
			}
		}

		float Radius { get { return Size / 2; } }

		float _angle;
		/** The angle, in degrees, at which light is hitting the element. */
		public float Angle
		{
			get { return _angle; }
			set
			{
				if (_angle != value)
				{
					_angle = value;

					if (Active)
					{
						OnRenderingChanged();
						OnRenderBoundsChanged();
					}
				}
			}
		}

		float _distance;
		/** The distance in points the shadow should be offset from its source. */
		public float Distance
		{
			get { return _distance; }
			set
			{
				if (_distance != value)
				{
					_distance = value;

					if (Active)
					{
						OnRenderingChanged();
						OnRenderBoundsChanged();
					}
				}
			}
		}

		float2 Offset
		{
			get
			{
				float th = Angle * (Math.PIf / 180);
				return float2(-Math.Cos(th), Math.Sin(th)) * Distance;
			}
		}

		float _spread;
		/** Controls how the shadow drops off. The closer to 0, the more linear. Keep this value low (experiment below 1.0), or you will get artifacts. */
		public float Spread
		{
			get { return _spread; }
			set
			{
				value = Math.Clamp(value, 0, 1);
				if (_spread != value)
				{
					bool wasActive = Active;

					_spread = value;

					if (wasActive || Active)
						OnRenderingChanged();
				}
			}
		}


		float4 _color;
		/**
			The color of the drop shadow.

		 	For more information on what notations Color supports, check out [this subpage](articles:ux-markup/literals#colors).
		*/
		public float4 Color
		{
			get
			{
				return _color;
			}
			set
			{
				if (_color != value)
				{
					bool wasActive = Active;

					_color = value;

					if (wasActive || Active)
						OnRenderingChanged();
				}
			}
		}

		internal float Sigma { get { return Math.Max(Radius, 1e-5f); } }
		internal float Padding { get { return Math.Ceil(Sigma * 3 * Element.AbsoluteZoom) / Element.AbsoluteZoom; } }

		public sealed override VisualBounds ModifyRenderBounds(VisualBounds inBounds)
		{
			var r = inBounds.InflateXY(Padding).Translate(float3(Offset,0));
			return inBounds.Merge(r);
		}

		public sealed override bool Active
		{
			get
			{
				return Color.W > 0.0f;
			}
		}

		protected sealed override void OnRender(DrawContext dc, Rect elementRect)
		{

			var temp = Element.CaptureRegion(dc, elementRect, float2(Padding));
			if (temp == null)
				return;

			var blur = EffectHelpers.Instance.Blur(temp.ColorBuffer, dc, Sigma * Element.AbsoluteZoom);

			float spreadScale = Math.Pow(1 / Math.Max(1 - Spread, 1e-10f), 2);
			Blitter.Instance.Blit(dc, Element, elementRect, Padding, temp.Size, blur.ColorBuffer, spreadScale, Offset, Color);

			FramebufferPool.Release(blur);
			FramebufferPool.Release(temp);
		}

		public DropShadow() : base(EffectType.Underlay)
		{
			Size = 5;
			Color = float4(0, 0, 0, 0.35f);
			Angle = 90;
			Distance = 3;
		}

		class Blitter
		{
			static Blitter _instance;
			public static Blitter Instance
			{
				get { return _instance ?? (_instance = new Blitter()); }
			}

			public void Blit(DrawContext dc, Element element, Rect elementRect, float padding, int2 tempSize, texture2D blurTexture, float spreadScale, float2 offset, float4 color)
			{
				draw Fuse.Drawing.Planar.Image
				{
					DrawContext: dc;
					Visual: element;
					Invert: true;
					Size: float2(tempSize.X, tempSize.Y) / element.AbsoluteZoom;
					Position: elementRect.Minimum + offset - padding;
					Texture: blurTexture;
					PixelColor: float4(color.XYZ, Math.Clamp(TextureColor.W * spreadScale, 0, 1) * color.W);
				};

				if defined(FUSELIBS_DEBUG_DRAW_RECTS)
					DrawRectVisualizer.Capture(elementRect.Minimum + offset - padding, float2(tempSize.X, tempSize.Y) / element.AbsoluteZoom, element.WorldTransform, dc);
			}

		}
	}
}
