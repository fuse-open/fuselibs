using Uno;

namespace Fuse.Controls.FallbackTextRenderer
{
	class WordWrapInfo
	{
		public readonly DefaultTextRenderer TextRenderer;
		public readonly bool IsEnabled;
		public readonly float WrapWidth;
		public readonly float FontSize;
		public readonly float LineHeight; //includes LineSpacing
		public readonly float LineSpacing;
		public readonly float AbsoluteZoom;

		public WordWrapInfo(DefaultTextRenderer textRenderer, bool isEnabled, float wrapWidth, float fontSize, float lineHeight, float lineSpacing, float absoluteZoom)
		{
			AbsoluteZoom = absoluteZoom;
			TextRenderer = textRenderer;
			IsEnabled = isEnabled;
			WrapWidth = wrapWidth;
			FontSize = fontSize;
			LineHeight = Math.Ceil(lineHeight * absoluteZoom) / absoluteZoom;
			LineHeight += lineSpacing * absoluteZoom;
			LineSpacing = lineSpacing * absoluteZoom;
		}

		public override bool Equals(object obj)
		{
			if (!(obj is WordWrapInfo))
				return false;

			var other = (WordWrapInfo)obj;
			return
				TextRenderer == other.TextRenderer &&
				IsEnabled == other.IsEnabled &&
				WrapWidth == other.WrapWidth &&
				FontSize == other.FontSize &&
				LineHeight == other.LineHeight &&
				LineSpacing == other.LineSpacing &&
				AbsoluteZoom == other.AbsoluteZoom;
		}

		public override int GetHashCode()
		{
			return
				TextRenderer.GetHashCode() ^
				IsEnabled.GetHashCode() ^
				WrapWidth.GetHashCode() ^
				FontSize.GetHashCode() ^
				LineHeight.GetHashCode() ^
				LineSpacing.GetHashCode() ^
				AbsoluteZoom.GetHashCode();
		}
	}
}
