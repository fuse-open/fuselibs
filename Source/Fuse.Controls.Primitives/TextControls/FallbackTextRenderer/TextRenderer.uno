using Uno;
using Uno.Collections;
using Uno.Graphics.Utils;
using Uno.Graphics.Utils.Text;
using Uno.UX;
using Fuse;
using Fuse.Elements;

namespace Fuse.Controls.FallbackTextRenderer
{
	sealed class TextRenderer : ITextRenderer
	{
		TextControl Control;
		public TextRenderer( TextControl text )
		{
			Control = text;
		}

		static Dictionary<Font, DefaultTextRenderer> _textRenderers = new Dictionary<Font, DefaultTextRenderer>();

		internal static DefaultTextRenderer GetTextRenderer(Font f)
		{
			DefaultTextRenderer tr;

			if (!_textRenderers.TryGetValue(f, out tr))
			{
				tr = new DefaultTextRenderer(LoadFont(f));
				_textRenderers.Add(f, tr);
			}

			return tr;

		}

		static FontFace LoadFont(Font font)
		{
			var bfs = font.FileSource as BundleFileSource;

			if (bfs != null)
			{
				return FontLoader.LoadFace(bfs.BundleFile);
			}
			else
			{
				return FontLoader.LoadFace(font.FileSource.ReadAllBytes());
			}
		}

		WordWrapInfo _wrapInfo;
		WrappedLine[] _wrappedLines;
		float _wrapWidth;
		Rect _textBounds;
		int _maxTextLength;
		string _cacheValue;
		bool _cacheMin;

		public float2 GetContentSize(LayoutParams lp)
		{
			if (Control == null)
				return float2(0);

			var wrapWidth = float.PositiveInfinity;
			if (Control.TextWrapping == TextWrapping.Wrap)
			{
				if (lp.HasX)
					wrapWidth = lp.X;
				if (lp.HasMaxX && lp.MaxX < wrapWidth)
					wrapWidth = lp.MaxX;
			}
			InitWrap(wrapWidth, Control.RenderValue ?? "", true);
			return _textBounds.Size;
		}

		void InitWrap(float wrapWidth, string value, bool useMin)
		{
			if (_wrapInfo != null && _wrapWidth == wrapWidth &&
				_cacheValue == value && _cacheMin == useMin)
				return;
			_wrapWidth = wrapWidth;
			_cacheValue = value;
			_cacheMin = useMin;

			var font = Control.Font;
			var renderer = GetTextRenderer(font);
			var fontSize = Control.FontSizeScaled;

			_wrapInfo = new WordWrapInfo(renderer, (Control.TextWrapping == TextWrapping.Wrap),
				wrapWidth, fontSize,
				renderer.GetLineHeight(fontSize), Control.LineSpacing, Control.AbsoluteZoom);

			var lines = value.Split('\n');
			var wrappedLines = new List<WrappedLine>();
			if (Control.TextWrapping == TextWrapping.Wrap)
			{
				foreach (var line in lines)
					wrappedLines.AddRange(WordWrapper.WrapLine(_wrapInfo, line));
			}
			else
			{
				var y = 0;
				foreach (var line in lines)
				{
					var lineSize = _wrapInfo.TextRenderer.MeasureStringVirtual(_wrapInfo.FontSize, _wrapInfo.AbsoluteZoom, line);
					var wrappedLine = new WrappedLine(line, 0, y++, lineSize.X);
					wrappedLines.Add(wrappedLine);
				}
			}
			_wrappedLines = wrappedLines.ToArray();

			float maxX = 0.0f;
			float minX = 0.0f;
			float height = 0.0f;
			int maxTextLength = 0;

			foreach (var wrappedLine in _wrappedLines)
			{
				var extent = float2(0, wrappedLine.LineWidth);

				if (!useMin)
				{
					switch (Control.TextAlignment)
					{
						case TextAlignment.Left:
							extent = float2(0,wrappedLine.LineWidth);
							break;
						case TextAlignment.Right:
							extent = float2(wrapWidth - wrappedLine.LineWidth, wrapWidth);
							break;
						case TextAlignment.Center:
							extent = float2(wrapWidth/2 - wrappedLine.LineWidth/2,
								wrapWidth/2 + wrappedLine.LineWidth/2);
							break;
					}
				}

				minX = Math.Min(minX,extent[0]);
				maxX = Math.Max(maxX,extent[1]);
				maxTextLength += wrappedLine.Text.Length;
				height += _wrapInfo.LineHeight;
			}

			//TODO: https://github.com/fusetools/fuselibs-private/issues/1386
			_textBounds = new Rect(float2(minX,0),float2(maxX, height));
			_maxTextLength = maxTextLength;
		}

		public void Draw(DrawContext dc, Fuse.Visual where)
		{
			UpdateArrange();

			//TODO: truncation!
			_wrapInfo.TextRenderer.BeginRendering(_wrapInfo.FontSize, _wrapInfo.AbsoluteZoom,
				where.WorldTransform, _size, Control.RenderColor, _maxTextLength);

			float y = _position.Y;
			foreach (var wrappedLine in _wrappedLines)
			{
				var x = wrappedLine.GetXOffset(Control.TextAlignment, _size.X, where.AbsoluteZoom);
				x += _position.X;
				_wrapInfo.TextRenderer.DrawLine(dc, x * _wrapInfo.AbsoluteZoom, y, wrappedLine.Text);
				y += _wrapInfo.LineHeight * _wrapInfo.AbsoluteZoom;
			}
			_wrapInfo.TextRenderer.EndRendering(dc);
		}

		float2 _position, _size;
		public void Arrange(float2 position, float2 size)
		{
			_position = position;
			_size = size;
			Invalidate();
			UpdateArrange();
		}

		void UpdateArrange()
		{
			if (_wrapInfo != null)
				return;

			var v = Control.RenderValue ?? "";
			InitWrap(_size.X, v, false);
		}

		public void Invalidate()
		{
			_wrapInfo = null;
		}

		public Rect GetRenderBounds()
		{
			return Rect.Translate(_textBounds,_position);
		}

		public void SoftDispose()
		{
			_wrapInfo = null;
		}
	}
}
