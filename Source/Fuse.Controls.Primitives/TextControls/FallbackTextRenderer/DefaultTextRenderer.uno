using Uno;
using Uno.Graphics;
using Uno.UX;
using Uno.Collections;
using Uno.Graphics.Utils.Text;

namespace Fuse.Controls.FallbackTextRenderer
{
	sealed class DefaultTextRenderer
	{
		class FontKey
		{
			public FontFace FontFace;
			public int Size;

			public override int GetHashCode()
			{
				return FontFace.GetHashCode() + (int)Size;
			}

			public override bool Equals(object obj)
			{
				if (obj is FontKey)
				{
					var fk = (FontKey)obj;
					return fk.Size == Size && fk.FontFace == FontFace;
				}
				return false;
			}

			public FontKey(FontFace fontFace, int size)
			{
				this.FontFace = fontFace;
				this.Size = size;
			} 
		}

		static Dictionary<FontKey, BitmapFont> _bitmapFonts;

		const int initialMaxCharCount = 100;
		static int _maxCharCount;

		static Uno.Graphics.Utils.Text.TextRenderer _renderer;

		static Uno.Graphics.Utils.Text.TextRenderer renderer
		{
			get
			{
				if (_renderer == null)
				{
					_renderer = new Uno.Graphics.Utils.Text.TextRenderer(initialMaxCharCount, new SpriteFontShader());
					_renderer.Transform = new ProperTextTransform();
				}
				return _renderer;
			}
		}

		public DefaultTextRenderer(FontFace fontFace)
		{
			if (_bitmapFonts == null)
			{
				_maxCharCount = initialMaxCharCount;
				_bitmapFonts = new Dictionary<FontKey, BitmapFont>();
			}

			FontFace = fontFace;
		}

		[UXPrimary]
		public FontFace FontFace { get; set; }

		public float GetLineHeight(float fontSize)
		{
			if (FontFace == null)
				return 0.0f;

			var size = Math.Clamp(fontSize, 4, 400);
			return FontFace.GetLineHeight(size);
		}

		public float GetLineHeightVirtual(float fontSize, float absoluteZoom)
		{
			return GetLineHeight(fontSize) / absoluteZoom;
		}

		public float2 MeasureString(float fontSize, float absoluteZoom, string s)
		{
			if (s == null)
				return float2(0);

			var bitmapFont = GetBitmapFont(fontSize, absoluteZoom, true);

			bool hasBegun = renderer.HasBegun;
			if (!hasBegun)
				renderer.Begin(bitmapFont);
			var ret = renderer.MeasureString(s);
			if (!hasBegun)
				renderer.End();

			return ret;
		}

		public float2 MeasureStringVirtual(float fontSize, float absoluteZoom, string s)
		{
			return Math.Ceil(MeasureString(fontSize, absoluteZoom, s) / absoluteZoom);
		}

		float _fontSize;
		float _absoluteZoom;
		float4x4 _transform;
		BitmapFont _bitmapFont;

		public void BeginRendering(float fontSize, float absoluteZoom, float4x4 transform, float2 bounds, float4 textColor, int maxTextLength)
		{
			_fontSize = fontSize;
			_absoluteZoom = absoluteZoom;

			_transform = transform;

			_bitmapFont = GetBitmapFont(_fontSize, _absoluteZoom, true);

			EnsureRendererCapacity(maxTextLength);

			renderer.Begin(_bitmapFont);
			renderer.Color = textColor;
		}

		public void EndRendering(DrawContext dc)
		{
			renderer.End();
		}


		public void DrawLine(DrawContext dc, float x, float y, string line)
		{
			var lineHeight = _bitmapFont.LineHeight;
			var lineOffsetY = lineHeight - _bitmapFont.Descent;

			var p = float2(x, y + lineOffsetY );

			if (dc.ViewportPixelsPerPoint != 1)
			{
				var scale = Matrix.Scaling(1/dc.ViewportPixelsPerPoint);
				renderer.Transform.Matrix = Matrix.Mul(scale,_transform);
			}
			else
			{
				renderer.Transform.Matrix = _transform;
			}

			(renderer.Transform as ProperTextTransform).DrawContext = dc;

			renderer.WriteString(p, line);
		}

		BitmapFont GetBitmapFont(float fontSize, float absoluteZoom, bool includeZoom)
		{
			var size = (int)Math.Floor(Math.Clamp(fontSize * (includeZoom ? absoluteZoom : 1.0f), 4, 400));

			var key = new FontKey(FontFace, size);
			BitmapFont bmpfont;
			if (!_bitmapFonts.TryGetValue(key, out bmpfont))
			{
				bmpfont = FontFace.RenderSpriteFont(size, CharacterSets.Ascii);
				_bitmapFonts.Add(key, bmpfont);
			}

			return bmpfont;
		}

		static void EnsureRendererCapacity(int maxCharCount)
		{
			if (maxCharCount <= _maxCharCount)
				return;

			_maxCharCount = Math.Max(_maxCharCount*2, maxCharCount);
			_renderer = new Uno.Graphics.Utils.Text.TextRenderer(_maxCharCount, new SpriteFontShader());
			_renderer.Transform = new ProperTextTransform();
		}
	}

	class ProperTextTransform : TextTransform
	{
		public DrawContext DrawContext;

		public override float4x4 ResolveClipSpaceMatrix()
		{
			return Uno.Matrix.Mul(Matrix,DrawContext.Viewport.ViewProjectionTransform);
		}

		public override PolygonFace CullFace
		{
			get { return DrawContext.CullFace; 	}
		}
	}

}
