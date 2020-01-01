using Uno;
using Uno.Collections;
using Uno.Graphics.Utils.Text;
using Fuse.Controls.FallbackTextRenderer;
using Fuse.Elements;

namespace Fuse.Controls.FallbackTextEdit
{
	class LineCacheLine
	{
		string _text;
		public string Text
		{
			get { return _text; }
			set
			{
				if (value == _text)
					return;

				_text = value;
				Invalidate();
			}
		}
		
		LineCacheTransform _transform;
		public LineCacheTransform Transform
		{
			get { return _transform; }
			set
			{
				_transform = value;
				Invalidate();
			}
		}
		
		public string VisualText
		{
			get 
			{
				if (_transform != null)
					return _transform.Transform(_text);
				return _text;
			}
		}

		WrappedLine[] _wrappedLinesCache;
		WordWrapInfo _wordWrapInfoCache;

		public WrappedLine[] GetWrappedLines(WordWrapInfo wrapInfo)
		{
			if (_wrappedLinesCache == null ||
				_wordWrapInfoCache == null ||
				!_wordWrapInfoCache.Equals(wrapInfo))
			{
				_wrappedLinesCache = wrapInfo.IsEnabled && Text.Length > 0 ?
					WordWrapper.WrapLine(wrapInfo, VisualText) :
					new[] { new WrappedLine(VisualText, 0, 0.0f, wrapInfo.TextRenderer.MeasureStringVirtual(wrapInfo.FontSize, wrapInfo.AbsoluteZoom, VisualText).X) };

				_wordWrapInfoCache = wrapInfo;
			}

			return _wrappedLinesCache;
		}

		public LineCacheLine(string text, LineCacheTransform transform)
		{
			_text = text;
			_transform = transform;
		}

		public void InsertChar(int p, char c)
		{
			Text = p < Text.Length ?
				Text.Substring(0, p) + c + Text.Substring(p) :
				Text + c;
		}

		public void Delete(int p)
		{
			Text = Text.Substring(0, p) + Text.Substring(p + 1);
		}

		public int Backspace(int p)
		{
			Text = Text.Substring(0, p - 1) + Text.Substring(p);
			return p - 1;
		}

		public int Home(WordWrapInfo wrapInfo, int p)
		{
			return PosToWrappedLine(wrapInfo, p).LineTextStartOffset;
		}

		public int End(WordWrapInfo wrapInfo, int p)
		{
			return PosToWrappedLine(wrapInfo, p).LineTextEndOffset;
		}

		public int BoundsToPos(WordWrapInfo wrapInfo, TextAlignment textAlignment, float boundsWidth, float2 p)
		{
			var wrappedLine = BoundsToWrappedLine(wrapInfo, p);

			var xOffset = wrappedLine.GetXOffset(textAlignment, boundsWidth, wrapInfo.AbsoluteZoom);
			return wrappedLine.BoundsToPos(wrapInfo, p.X - xOffset) + wrappedLine.LineTextStartOffset;
		}

		public float2 PosToBounds(WordWrapInfo wrapInfo, TextAlignment textAlignment, float boundsWidth, int p)
		{
			var wrappedLine = PosToWrappedLine(wrapInfo, p);

			var xOffset = wrappedLine.GetXOffset(textAlignment, boundsWidth, wrapInfo.AbsoluteZoom);
			var yOffset = wrappedLine.YOffset;
			return float2(xOffset + wrappedLine.PosToBounds(wrapInfo, p - wrappedLine.LineTextStartOffset), yOffset);
		}

		public float GetTotalHeight(WordWrapInfo wrapInfo)
		{
			var wrappedLines = GetWrappedLines(wrapInfo);
			return (float)wrappedLines.Length * wrapInfo.LineHeight;
		}

		WrappedLine BoundsToWrappedLine(WordWrapInfo wrapInfo, float2 p)
		{
			var wrappedLines = GetWrappedLines(wrapInfo);

			int l = 0;
			float startY = 0.0f;
			if (p.Y > 0.0f)
			{
				for (; l < wrappedLines.Length - 1; l++)
				{
					float endY = startY + wrapInfo.LineHeight;
					if (p.Y >= startY && p.Y < endY)
						break;
					startY = endY;
				}
			}

			return wrappedLines[l];
		}

		WrappedLine PosToWrappedLine(WordWrapInfo wrapInfo, int p)
		{
			var wrappedLines = GetWrappedLines(wrapInfo);

			for (int i = 0; i < wrappedLines.Length - 1; i++)
			{
				var wrappedLine = wrappedLines[i];
				if (p >= wrappedLine.LineTextStartOffset && p < wrappedLine.LineTextEndOffset)
					return wrappedLine;
			}

			return wrappedLines[wrappedLines.Length - 1];
		}

		public void Invalidate()
		{
			_wrappedLinesCache = null;
		}
	}
}
