using Uno.Collections;
using Uno.Graphics.Utils.Text;

namespace Fuse.Controls.FallbackTextRenderer
{
	class WordWrapperWord
	{
		public readonly string Contents;
		public readonly string Whitespace;
		public readonly string TotalContents;
		public readonly int StartIndex;
		public readonly float ContentsWidth;
		public readonly float TotalContentsWidth;

		public int EndIndex { get { return StartIndex + TotalContents.Length; } }

		public WordWrapperWord(string contents, string whitespace, int startIndex, float contentsWidth, float totalContentsWidth)
		{
			Contents = contents;
			Whitespace = whitespace;
			TotalContents = Contents + Whitespace;
			StartIndex = startIndex;
			ContentsWidth = contentsWidth;
			TotalContentsWidth = totalContentsWidth;
		}
	}

	static class WordWrapper
	{
		public static WrappedLine[] WrapLine(WordWrapInfo wrapInfo, string text)
		{
			var words = GetWords(wrapInfo, text);

			var ret = new List<WrappedLine>();
			if (words.Count == 0)
				return ret.ToArray();

			int lineStartIndex = 0;
			var lineText = string.Empty;
			float lineWidth = 0.0f;

			for (int i = 0; i < words.Count - 1; i++)
			{
				var word = SplitWord(wrapInfo, ret, words[i], ref lineStartIndex);

				var nextWord = words[i + 1];

				if (lineWidth + word.TotalContentsWidth + nextWord.ContentsWidth <= wrapInfo.WrapWidth)
				{
					lineText += word.TotalContents;
					lineWidth += word.TotalContentsWidth;
				}
				else
				{
					ret.Add(new WrappedLine(lineText + word.TotalContents, lineStartIndex, (float)ret.Count * wrapInfo.LineHeight, lineWidth + word.ContentsWidth));

					lineStartIndex = nextWord.StartIndex;
					lineText = string.Empty;
					lineWidth = 0.0f;
				}
			}

			var lastWord = SplitWord(wrapInfo, ret, words[words.Count - 1], ref lineStartIndex);
			ret.Add(new WrappedLine(lineText + lastWord.TotalContents, lineStartIndex, (float)ret.Count * wrapInfo.LineHeight, lineWidth + lastWord.TotalContentsWidth));

			return ret.ToArray();
		}

		static List<WordWrapperWord> GetWords(WordWrapInfo wrapInfo, string text)
		{
			var ret = new List<WordWrapperWord>();

			for (int i = 0; i < text.Length; )
			{
				int contentsIndex = i;
				int contentsLength = 0;
				for (; i < text.Length && !char.IsWhiteSpace(text[i]); i++)
					contentsLength++;
				var contents = text.Substring(contentsIndex, contentsLength);

				int whitespaceIndex = i;
				int whitespaceLength = 0;
				for (; i < text.Length && char.IsWhiteSpace(text[i]); i++)
					whitespaceLength++;
				var whitespace = text.Substring(whitespaceIndex, whitespaceLength);

				ret.Add(new WordWrapperWord(
					contents, whitespace, contentsIndex,
					wrapInfo.TextRenderer.MeasureStringVirtual(wrapInfo.FontSize, wrapInfo.AbsoluteZoom, contents).X,
					wrapInfo.TextRenderer.MeasureStringVirtual(wrapInfo.FontSize, wrapInfo.AbsoluteZoom, contents + whitespace).X));
			}

			return ret;
		}

		static WordWrapperWord SplitWord(WordWrapInfo wrapInfo, List<WrappedLine> wrappedLines, WordWrapperWord word, ref int lineStartIndex)
		{
			while (word.Contents.Length > 1 && word.ContentsWidth > wrapInfo.WrapWidth)
			{
				int c = 1;
				for (; c < word.Contents.Length; c++)
				{
					var leftString = word.Contents.Substring(0, c);
					float startX = wrapInfo.TextRenderer.MeasureStringVirtual(wrapInfo.FontSize, wrapInfo.AbsoluteZoom, leftString).X;
					if (startX >= wrapInfo.WrapWidth)
						return word;
					float endX = startX + wrapInfo.TextRenderer.MeasureStringVirtual(wrapInfo.FontSize, wrapInfo.AbsoluteZoom, word.Contents.Substring(c, 1)).X;
					if (startX < wrapInfo.WrapWidth && endX >= wrapInfo.WrapWidth)
					{
						wrappedLines.Add(new WrappedLine(leftString, word.StartIndex, (float)wrappedLines.Count * wrapInfo.LineHeight, startX));
						var newWordContents = word.Contents.Substring(c);
						lineStartIndex = word.StartIndex + c;
						word = new WordWrapperWord(
							newWordContents, word.Whitespace, lineStartIndex,
							wrapInfo.TextRenderer.MeasureStringVirtual(wrapInfo.FontSize, wrapInfo.AbsoluteZoom, newWordContents).X,
							wrapInfo.TextRenderer.MeasureStringVirtual(wrapInfo.FontSize, wrapInfo.AbsoluteZoom, newWordContents + word.Whitespace).X);
						break;
					}
				}
			}

			return word;
		}
	}
}
