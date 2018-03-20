using Uno;
using Fuse.Elements;

namespace Fuse.Controls.FallbackTextRenderer
{
	class WrappedLine
	{
		public readonly string Text;
		public readonly int LineTextStartOffset;
		public readonly float YOffset;
		public readonly float LineWidth;

		public int LineTextEndOffset { get { return LineTextStartOffset + Text.Length; } }

		public WrappedLine(string text, int lineTextStartOffset, float yOffset, float lineWidth)
		{
			Text = text;
			LineTextStartOffset = lineTextStartOffset;
			YOffset = yOffset;
			LineWidth = lineWidth;
		}

		public float GetXOffset(TextAlignment textAlignment, float boundsWidth, float absoluteZoom)
		{
			switch (textAlignment)
			{
				case TextAlignment.Left:
					return 0.0f;

				case TextAlignment.Center:
					return Math.Floor((boundsWidth - LineWidth) / 2.0f * absoluteZoom + 0.5f) / absoluteZoom;

				case TextAlignment.Right:
					return boundsWidth - LineWidth;
			}

			throw new ArgumentException("unsupported enum-value", "textAlignment"); // TODO: replace with InvalidEnumArgumentException when we get that
		}

		public int BoundsToPos(WordWrapInfo wrapInfo, float p)
		{
			int c = 0;
			if (p > 0.0f)
			{
				for (; c < Text.Length; c++)
				{
					float startX = wrapInfo.TextRenderer.MeasureStringVirtual(wrapInfo.FontSize, wrapInfo.AbsoluteZoom, Text.Substring(0, c)).X;
					if (p >= startX)
					{
						float charWidth = wrapInfo.TextRenderer.MeasureStringVirtual(wrapInfo.FontSize, wrapInfo.AbsoluteZoom, Text.Substring(c, 1)).X;
						float endX = startX + charWidth;
						if (p < endX)
						{
							float charPos = (p - startX) / charWidth;
							if (charPos >= 0.5f)
								c = Math.Clamp(c + 1, 0, Text.Length - 1);

							break;
						}
					}
				}
			}
			return c;
		}

		public float PosToBounds(WordWrapInfo wrapInfo, int p)
		{
			return wrapInfo.TextRenderer.MeasureStringVirtual(wrapInfo.FontSize, wrapInfo.AbsoluteZoom, Text.Substring(0, p)).X;
		}
	}
}
