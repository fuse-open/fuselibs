using Uno;
using Uno.Collections;
using Uno.Graphics.Utils.Text;

using Fuse.Controls.FallbackTextRenderer;
using Fuse.Elements;

namespace Fuse.Controls.FallbackTextEdit
{
	class LineCache
	{
		List<LineCacheLine> _lines;
		public List<LineCacheLine> Lines
		{
			get
			{
				if (_lines == null)
					_lines = DecomposeLines(_text);

				return _lines;
			}
		}

		string _text;
		bool _isTextValid = true;
		public string Text
		{
			get
			{
				if (!_isTextValid)
				{
					// TODO: Use Aggregate when it's implemented
					_text = Lines.First().Text;
					for (int i = 1; i < Lines.Count; i++)
						_text = _text + "\n" + Lines[i].Text;
					_isTextValid = true;
				}

				return _text;
			}
			set
			{
				if (value == Text)
					return;

				_text = value;
				_isTextValid = true;

				_lines = null;
			}
		}

		
		LineCacheTransform _transform;
		public LineCacheTransform Transform
		{
			get { return _transform; }
			set
			{
				_transform = value;
				foreach( var line in Lines )
					line.Transform = _transform;
				InvalidateText(true);
			}
		}

		readonly bool _isMultiline;
		readonly Action _onTextChanged;
		readonly Action _invalideLayout;

		public LineCache(Action onTextChanged, Action invalideLayout, bool isMultiline)
		{
			_isMultiline = isMultiline;
			_onTextChanged = onTextChanged;
			_invalideLayout = invalideLayout;

			_lines = null;
		}

		public TextPosition InsertChar(TextPosition p, char c)
		{
			Lines[p.Line].InsertChar(p.Char, c);
			InvalidateText();
			return new TextPosition(p.Line, p.Char + 1);
		}

		public TextPosition InsertNewline(TextPosition p)
		{
			var currentLine = Lines[p.Line];
			var newLine = new LineCacheLine(currentLine.Text.Substring(p.Char), _transform);
			currentLine.Text = currentLine.Text.Substring(0, p.Char);
			Lines.Insert(p.Line + 1, newLine);
			InvalidateText();
			return new TextPosition(p.Line + 1, 0);
		}

		public TextPosition TryDelete(TextPosition p)
		{
			var line = Lines[p.Line];
			if (p.Char == line.Text.Length)
			{
				if (p.Line == Lines.Count - 1)
					return p;

				var nextLine = Lines[p.Line + 1];
				line.Text = line.Text + nextLine.Text;
				Lines.RemoveAt(p.Line + 1);
				InvalidateText();
			}
			else
			{
				Lines[p.Line].Delete(p.Char);
				InvalidateText();
			}

			return p;
		}

		public TextPosition TryBackspace(TextPosition p)
		{
			if (p.Char == 0)
			{
				if (p.Line == 0)
					return p;

				var prevLine = Lines[p.Line - 1];
				var currentLine = Lines[p.Line];
				int newChar = prevLine.Text.Length;
				prevLine.Text = prevLine.Text + currentLine.Text;
				Lines.RemoveAt(p.Line);
				InvalidateText();
				return new TextPosition(p.Line - 1, newChar);
			}

			var ret = new TextPosition(p.Line, Lines[p.Line].Backspace(p.Char));
			InvalidateText();
			return ret;
		}

		public TextPosition DeleteSpan(TextSpan s)
		{
			if (s == GetFullTextSpan())
			{
				Text = "";
			}
			else
			{
				for (int i = Lines.Count - 1; i >= 0; i--)
				{
					var line = Lines[i];
					var lineSpan = new TextSpan(new TextPosition(i, 0), new TextPosition(i, line.Text.Length));
					var intersection = TextSpan.Intersection(lineSpan, s);
					if (intersection == null)
						continue;

					if (intersection == lineSpan)
					{
						Lines.RemoveAt(i);
					}
					else
					{
						var text = Lines[i].Text;
						var start = text.Substring(0, intersection.Start.Char);
						var end = text.Substring(intersection.End.Char, text.Length - intersection.End.Char);
						Lines[i].Text = start + end;
					}
				}
			}

			InvalidateText();

			return new TextPosition(Math.Min(s.Start.Line, Lines.Count - 1), s.Start.Char);
		}

		public TextPosition TryMoveLeft(TextPosition p)
		{
			if (p.Char == 0)
			{
				if (p.Line == 0)
					return p;

				var prevLine = Lines[p.Line - 1];
				return new TextPosition(p.Line - 1, prevLine.Text.Length);
			}
			return new TextPosition(p.Line, p.Char - 1);
		}

		public TextPosition TryMoveRight(TextPosition p)
		{
			var line = Lines[p.Line];
			if (p.Char >= line.Text.Length)
			{
				if (p.Line == Lines.Count - 1)
					return p;

				return new TextPosition(p.Line + 1, 0);
			}
			return new TextPosition(p.Line, p.Char + 1);
		}

		public TextPosition TryMoveOneWordLeft(TextPosition p)
		{
			if (p.Char == 0)
			{
				if (p.Line == 0)
					return p;

				var prevLine = Lines[p.Line - 1];
				return new TextPosition(p.Line - 1, prevLine.Text.Length);
			}

			return new TextPosition(p.Line, NextWordLeft(Lines[p.Line].Text, p.Char));
		}

		int NextWordLeft(string str, int startIdx)
		{
			// Same behaviour as Sublime Text
			bool hitWordBreak = false;
			int nextRealChar = -1;

			var i = startIdx - 1;
			bool startsWithRealChar = !IsWordBreaker(str[i]);
			for(;i >= 0;--i)
			{
				var c = str[i];
				if(IsWordBreaker(c))
				{
					hitWordBreak = true;
					if(startsWithRealChar)
					{
						nextRealChar = i;
						break;
					}
				}
				else if(hitWordBreak)
				{
					startsWithRealChar = true;
					hitWordBreak = false;
				}
			}

			if(i == -1)
				return 0;

			return nextRealChar + 1;
		}

		public TextPosition TryMoveOneWordRight(TextPosition p)
		{
			var line = Lines[p.Line];
			if(p.Char >= line.Text.Length)
			{
				if (p.Line == Lines.Count - 1)
					return p;

				return new TextPosition(p.Line + 1, 0);
			}

			return new TextPosition(p.Line, NextWordRight(line.Text, p.Char));
		}

		int NextWordRight(string str, int startIdx)
		{
			// Same behaviour as Sublime Text
			bool hitWordBreak = false;
			int nextRealChar = -1;

			var i = startIdx;
			bool startsWithRealChar = !IsWordBreaker(str[i]);
			for(;i < str.Length;++i)
			{
				var c = str[i];
				if(IsWordBreaker(c))
				{
					hitWordBreak = true;
					if(startsWithRealChar)
					{
						nextRealChar = i;
						break;
					}
				}
				else if(hitWordBreak)
				{
					startsWithRealChar = true;
					hitWordBreak = false;
				}
			}

			if(i == str.Length)
				return i;

			return nextRealChar;
		}

		bool IsWordBreaker(char c)
		{
			// TODO: Make this more sophisticated
			return c == ' ' || c == '\t' || c == '\n' || c == '.' || c == ',' || c == ';';
		}

		// TODO: Make this and TryMoveDown not shift the cursor to the left over time
		// This is most likely actually related to how the lines' BoundsToPos methods
		// don't bias towards the middle of the character, but the left edge instead.
		// Actually, though, this could probably be fixed just by implementing the
		// 'try to preserve cursor X while moving accross lines of widely varying
		// width' feature, as that should keep the cursor from drifting by definition.
		public TextPosition TryMoveUp(WordWrapInfo wrapInfo, TextAlignment textAlignment, float boundsWidth, TextPosition p)
		{
			var lineBounds = TextPosToBounds(wrapInfo, textAlignment, boundsWidth, p);
			var prevLineBounds = float2(lineBounds.X, lineBounds.Y - wrapInfo.LineHeight * .5f);
			var prevLineTextPos = BoundsToTextPos(wrapInfo, textAlignment, boundsWidth, prevLineBounds);

			return prevLineTextPos;
		}

		public TextPosition TryMoveDown(WordWrapInfo wrapInfo, TextAlignment textAlignment, float boundsWidth, TextPosition p)
		{
			var lineBounds = TextPosToBounds(wrapInfo, textAlignment, boundsWidth, p);
			var nextLineBounds = float2(lineBounds.X, lineBounds.Y + wrapInfo.LineHeight * 1.5f);
			var nextLineTextPos = BoundsToTextPos(wrapInfo, textAlignment, boundsWidth, nextLineBounds);

			return nextLineTextPos;
		}

		public TextPosition Home(WordWrapInfo wrapInfo, TextPosition p)
		{
			return new TextPosition(p.Line, Lines[p.Line].Home(wrapInfo, p.Char));
		}

		public TextPosition End(WordWrapInfo wrapInfo, TextPosition p)
		{
			return new TextPosition(p.Line, Lines[p.Line].End(wrapInfo, p.Char));
		}

		public float2 GetBoundsSize(WordWrapInfo wrapInfo)
		{
			float maxWidth = 0.0f;
			float height = 0.0f;
			foreach (var line in Lines)
			{
				foreach (var wrappedLine in line.GetWrappedLines(wrapInfo))
				{
					maxWidth = Math.Max(maxWidth, wrappedLine.LineWidth);
					height += wrapInfo.LineHeight;
				}
			}
			return float2(maxWidth, height);
		}

		public TextPosition BoundsToTextPos(WordWrapInfo wrapInfo, TextAlignment textAlignment, float boundsWidth, float2 p)
		{
			int l = 0;
			float startY = 0.0f;
			if (p.Y > 0.0f)
			{
				for (; l < Lines.Count - 1; l++)
				{
					float lineHeight = Lines[l].GetTotalHeight(wrapInfo);
					float endY = startY + lineHeight;
					if (p.Y >= startY && p.Y < endY)
						break;
					startY = endY;
				}
			}

			int c = Lines[l].BoundsToPos(wrapInfo, textAlignment, boundsWidth, float2(p.X, p.Y - startY));

			return new TextPosition(l, c);
		}

		public float2 TextPosToBounds(WordWrapInfo wrapInfo, TextAlignment textAlignment, float boundsWidth, TextPosition p)
		{
			float startY = 0.0f;
			for (int i = 0; i < p.Line; i++)
				startY += Lines[i].GetTotalHeight(wrapInfo);

			var linePos = Lines[p.Line].PosToBounds(wrapInfo, textAlignment, boundsWidth, p.Char);

			return float2(linePos.X, startY + linePos.Y);
		}

		public TextPosition GetLastTextPos()
		{
			return new TextPosition(Lines.Count - 1, Lines[Lines.Count - 1].Text.Length);
		}

		public TextSpan GetFullTextSpan()
		{
			return new TextSpan(TextPosition.Default, GetLastTextPos());
		}

		public string GetString(TextSpan s)
		{
			// TODO: Use Aggregate when it's implemented
			var ret = "";

			for (int i = s.Start.Line; i <= s.End.Line; i++)
			{
				var line = Lines[i];
				var lineSpan = new TextSpan(new TextPosition(i, 0), new TextPosition(i, line.Text.Length));
				var intersection = TextSpan.Intersection(lineSpan, s);
				if (intersection == null)
					continue;

				ret += line.Text.Substring(intersection.Start.Char, intersection.End.Char - intersection.Start.Char);
			}

			return ret;
		}

		public void InvalidateVisual()
		{
			foreach( var line in Lines )
				line.Invalidate();
			InvalidateLayout();
		}
		void InvalidateText(bool noChange = false)
		{
			_text = null;
			_isTextValid = false;
			if (!noChange && _onTextChanged != null)
				_onTextChanged();
			InvalidateLayout();
		}

		void InvalidateLayout()
		{
			if (_invalideLayout != null)
				_invalideLayout();
		}

		List<LineCacheLine> DecomposeLines(string text)
		{
			var lines = new List<LineCacheLine>();
			if (text != null)
			{
				if (_isMultiline)
				{
					// TODO: AddRange + Select when lambda's are implemented
					foreach (var line in text.Split(new[] { '\n' }))
						lines.Add(new LineCacheLine(line, _transform));
				}
				else
				{
					lines.Add(new LineCacheLine(text, _transform));
				}
			}
			if (lines.Count == 0)
				lines.Add(new LineCacheLine(string.Empty, _transform));
			return lines;
		}
	}
}
