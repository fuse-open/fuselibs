using Uno;
using Uno.Collections;
using Uno.Collections.EnumerableExtensions;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Text
{
	public class Substring : IEnumerable<char>
	{
		internal readonly string _parent;
		internal readonly int _start;
		public readonly int Length;

		public Substring(string parent)
			: this(parent, 0)
		{
		}

		public Substring(string parent, int start)
			: this(parent, start, parent.Length - start)
		{
		}

		public Substring(string parent, int start, int length)
		{
			if (length > 0 && (start < 0 || start >= parent.Length))
				throw new ArgumentOutOfRangeException(nameof(start));
			if (start + length < 0 || start + length > parent.Length)
				throw new ArgumentOutOfRangeException(nameof(length));
			_parent = parent;
			_start = start;
			Length = length;
		}

		public override string ToString()
		{
			if (_start == 0 && Length == _parent.Length)
				return _parent;
			return _parent.Substring(_start, Length);
		}

		public override bool Equals(object o)
		{
			var ss = o as Substring;
			return ss == null ? false : Equals(ss);
		}

		public bool Equals(Substring s)
		{
			if (ReferenceEquals(this, s))
				return true;
			if (ReferenceEquals(_parent, s._parent) && _start == s._start && Length == s.Length)
				return true;
			return Length == s.Length && SequenceEqual(this, s);
		}

		public override int GetHashCode()
		{
			int hash = 5381;
			foreach (char c in this)
				hash = ((hash << 5) + hash) ^ (int)c;
			return hash;
		}

		public char this[int index]
		{
			get
			{
				if (index < 0 || index >= Length)
					throw new ArgumentOutOfRangeException(nameof(index));
				return _parent[_start + index];
			}
		}

		public Substring GetSubstring(int start, int length)
		{
			if (Length > 0 && length > 0 && (start < 0 || start >= Length))
				throw new ArgumentOutOfRangeException(nameof(start));
			if (length < 0 || start + length > Length)
				throw new ArgumentOutOfRangeException(nameof(length));
			return new Substring(_parent, _start + start, length);
		}

		public Substring GetSubstring(int start)
		{
			if (Length > 0 && (start < 0 || start > Length))
				throw new ArgumentOutOfRangeException(nameof(start));
			return new Substring(_parent, _start + start, Length - start);
		}

		public Substring TrimLeadingNewline()
		{
			if (Length >= 1 && this[0] == '\n')
				return GetSubstring(1);
			if (Length >= 2 && this[0] == '\r' && this[1] == '\n')
				return GetSubstring(2);
			return this;

		}

		public Substring TrimTrailingNewline()
		{
			if (Length >= 1 && this[Length - 1] == '\n')
			{
				if (Length >= 2 && this[Length - 2] == '\r')
					return GetSubstring(0, Length - 2);
				return GetSubstring(0, Length - 1);
			}

			return this;
		}

		public IEnumerator<char> GetEnumerator()
		{
			return new CharEnumerator(this);
		}

		class CharEnumerator : IEnumerator<char>
		{
			int _index;
			readonly Substring _text;

			public CharEnumerator(Substring text)
			{
				_text = text;
				Reset();
			}

			public void Reset()
			{
				_index = -1;
			}

			public bool MoveNext()
			{
				++_index;
				return _index < _text.Length;
			}

			public char Current
			{
				get
				{
					return _text[_index];
				}
			}

			public void Dispose()
			{
				// Nothing to do
			}
		}

		public IEnumerable<Substring> Lines
		{
			get
			{
				return new LineEnumerable(this);
			}
		}

		class LineEnumerable : IEnumerable<Substring>
		{
			readonly Substring _text;

			public LineEnumerable(Substring text)
			{
				_text = text;
			}

			public IEnumerator<Substring> GetEnumerator()
			{
				return new LineEnumerator(_text);
			}
		}

		class LineEnumerator : IEnumerator<Substring>
		{
			readonly Substring _text;
			int _lineStart;
			int _lineLength;
			int _skip;
			bool _newlineFound;

			public LineEnumerator(Substring text)
			{
				_text = text;
				Reset();
			}

			public void Reset()
			{
				_lineStart = 0;
				_lineLength = -1;
				_skip = 0;
			}

			public bool MoveNext()
			{
				// True unless we're at the very start
				if (_lineLength >= 0)
				{
					_lineStart += _lineLength;

					if (_lineStart >= _text.Length)
						return false;
				}

				int i = _lineStart + _skip;

				// Find the next newline
				while (i < _text.Length)
				{
					var c = _text[i];
					if (c == '\n')
					{
						_skip = 1;
						_lineLength = i - _lineStart;
						return true;
					}
					if (c == '\r' && i + 1 < _text.Length && _text[i + 1] == '\n')
					{
						_skip = 2;
						_lineLength = i - _lineStart;
						return true;
					}
					++i;
				}

				// Or the end of the string
				_skip = 0;
				_lineLength = _text.Length - _lineStart;
				return true;
			}

			public Substring Current
			{
				get
				{
					if (_lineLength < 0)
						throw new Exception("Calling Current on an invalid LineEnumerator");
					return _text.GetSubstring(_lineStart, _lineLength);
				}
			}

			public void Dispose()
			{
				// Nothing to do
			}
		}
	}

	static class SubstringExtensions
	{
		static bool IsLeadingSurrogate(char c)
		{
			var codePoint = (int)c;
			return 0xD800 <= codePoint && codePoint <= 0xDBFF;
		}

		static bool IsTrailingSurrogate(char c)
		{
			var codePoint = (int)c;
			return 0xDC00 <= codePoint && codePoint <= 0xDFFF;
		}

		public static int CharStart(this Substring s, int i)
		{
			if (i < 0 || i >= s.Length)
				throw new ArgumentException(nameof(i));
			if (IsTrailingSurrogate(s[i]))
			{
				--i;
				if (i < 0)
					throw new ArgumentException(nameof(s));
			}
			return i;
		}

		public static int CharStart(this string s, int i)
		{
			if (i < 0 || i >= s.Length)
				throw new ArgumentException(nameof(i));
			if (IsTrailingSurrogate(s[i]))
			{
				--i;
				if (i < 0)
					throw new ArgumentException(nameof(s));
			}
			return i;
		}

		public static Substring InclusiveRange(this Substring s, int start, int end)
		{
			assert !IsTrailingSurrogate(s[start]);
			if (IsLeadingSurrogate(s[end])) ++end;

			assert end < s.Length;

			return s.GetSubstring(start, end - start + 1);
		}

		public static int NextCharIndex(this string s, int i)
		{
			if (i < 0)
				i = -1;
			if (i + 1 >= s.Length)
				return s.Length;

			if (IsTrailingSurrogate(s[i + 1]))
				return i + 2;
			return i + 1;
		}

		public static int PrevCharIndex(this string s, int i)
		{
			if (i > s.Length)
				i = s.Length;
			if (i - 1 < 0)
				return -1;

			if (IsTrailingSurrogate(s[i - 1]))
				return i - 2;
			return i - 1;
		}

		public static string SafeSubstring(this string s, int start, int length)
		{
			if (start >= s.Length) return "";
			if (length <= 0) return "";
			length = Math.Min(length, s.Length - start);
			return s.Substring(start, length);
		}

		public static string SafeSubstring(this string s, int start)
		{
			if (start >= s.Length) return "";
			return s.Substring(start);
		}

		public static string DeleteAt(this string s, ref int index)
		{
			var len = 1;
			if (IsLeadingSurrogate(s[index]))
				len = 2;
			if (IsTrailingSurrogate(s[index]))
			{
				index -= 1;
				len = 2;
			}

			return s.SafeSubstring(0, index) +
				s.SafeSubstring(index + len);
		}

		public static string SafeInsert(this string s, int index, string insert)
		{
			index = Math.Clamp(index, 0, s.Length);
			return s.Insert(index, insert);
		}

		public static string DeleteSpan(this string s, int start, int end)
		{
			if (IsTrailingSurrogate(s[start]))
				--start;
			if (IsLeadingSurrogate(s[end]))
				++end;

			return s.SafeSubstring(0, start) + s.SafeSubstring(end + 1);
		}

		public static IEnumerable<Substring> TrimmedLines(this Substring str)
		{
			return str.Lines.Select(new Func<Substring, Substring>(TrimLine));
		}

		static Substring TrimLine(Substring line)
		{
			var trimmedLine = line.TrimLeadingNewline();
			if (trimmedLine.Length == 0)
				return line;
			return trimmedLine;
		}
	}
}
