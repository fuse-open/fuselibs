using Uno;

using Fuse.Common;
using Fuse.Controls.FallbackTextRenderer;
using Fuse.Elements;

namespace Fuse.Controls.FallbackTextEdit
{
	class TextWindow : Element
	{
		readonly LineCache _lineCache;

		public TextWindow(Visual parent, LineCache lineCache)
		{
			_lineCache = lineCache;

			ClipToBounds = true;
		}

		WordWrapInfo _wrapInfo;
		TextSpan _selection;
		float4 _textColor;
		float4 _selectionColor;
		int _maxTextLength;
		TextAlignment _textAlignment;
		float2 _textBoundsSize;
		float2 _offset;

		protected override VisualBounds CalcRenderBounds()
		{
			return VisualBounds.Rect(float2(0), _textBoundsSize);
		}

		public void Draw(WordWrapInfo wrapInfo, TextSpan selection, float4 textColor, float4 selectionColor, int maxTextLength, TextAlignment textAlignment, float2 textBoundsSize, float2 offset, DrawContext dc)
		{
			if (_textBoundsSize != textBoundsSize)
				InvalidateRenderBounds();

			_wrapInfo = wrapInfo;
			_selection = selection;
			_textColor = textColor;
			_selectionColor = selectionColor;
			_maxTextLength = maxTextLength;
			_textAlignment = textAlignment;
			_textBoundsSize = textBoundsSize;
			_offset = offset;

			OnDraw(dc);
		}

		protected override void OnDraw(DrawContext dc)
		{
			_wrapInfo.TextRenderer.BeginRendering(_wrapInfo.FontSize, _wrapInfo.AbsoluteZoom, 
				WorldTransform, ActualSize, _textColor, _maxTextLength);

			float lineHeight = _wrapInfo.LineHeight * _wrapInfo.AbsoluteZoom;
			var scaledOffset = _offset * _wrapInfo.AbsoluteZoom;
			float y = 0.0f;
			float selectionY = 0.0f;
			for (int i = 0; i < _lineCache.Lines.Count; i++)
			{
				var lines = _lineCache.Lines[i].GetWrappedLines(_wrapInfo);

				for (int j = 0; j < lines.Length; ++j)
				{
					var wrappedLine = lines[j];

					var drawY = scaledOffset.Y + y;
					if (drawY >= ActualSize.Y * _wrapInfo.AbsoluteZoom)
					{
						break;
					}
					else if (drawY >= -lineHeight)
					{
						var x = wrappedLine.GetXOffset(_textAlignment, _textBoundsSize.X, AbsoluteZoom);

						if (_selection != null)
						{
							var start = new TextPosition(i, wrappedLine.LineTextStartOffset);
							var end = new TextPosition(i, wrappedLine.LineTextEndOffset);
							var span = new TextSpan(start, end);
							var intersection = TextSpan.Intersection(span, _selection);
							if (intersection != null)
							{
								var startPos = wrappedLine.PosToBounds(_wrapInfo, intersection.Start.Char - wrappedLine.LineTextStartOffset);
								var endPos = intersection.End.Char < wrappedLine.LineTextEndOffset ?
									wrappedLine.PosToBounds(_wrapInfo, intersection.End.Char - wrappedLine.LineTextStartOffset) :
									wrappedLine.LineWidth;

								var localRect = new Rect(
									Math.Floor(float2(_offset.X + x + startPos, _offset.Y + selectionY)),
									float2(endPos - startPos, _wrapInfo.LineHeight));
								Blitter.Singleton.Fill(localRect, dc.GetLocalToClipTransform(this), _selectionColor);
							}
						}

						_wrapInfo.TextRenderer.DrawLine(dc, scaledOffset.X + x * _wrapInfo.AbsoluteZoom, drawY, wrappedLine.Text);
					}
					y += lineHeight;
					selectionY += lineHeight / _wrapInfo.AbsoluteZoom;
				}
			}

			_wrapInfo.TextRenderer.EndRendering(dc);
		}
	}
}
