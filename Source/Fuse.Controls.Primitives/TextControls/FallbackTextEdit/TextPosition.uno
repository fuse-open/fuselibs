using Uno;
using Fuse.Controls.FallbackTextRenderer;

namespace Fuse.Controls.FallbackTextEdit
{
	class TextPosition
	{
		public static readonly TextPosition Default = new TextPosition(0, 0);

		public static bool operator ==(TextPosition a, TextPosition b)
		{
			var aNull = ReferenceEquals(a, null);
			var bNull = ReferenceEquals(b, null);

			if (aNull && bNull)
				return true;

			if ((aNull && !bNull) || (!aNull && bNull))
				return false;

			return a.Equals(b);
		}

		public static bool operator !=(TextPosition a, TextPosition b)
		{
			return !(a == b);
		}

		public static bool operator <(TextPosition a, TextPosition b)
		{
			if (a.Line < b.Line)
				return true;

			if (a.Line > b.Line)
				return false;

			return a.Char < b.Char;
		}

		public static bool operator <=(TextPosition a, TextPosition b)
		{
			if (a.Line < b.Line)
				return true;

			if (a.Line > b.Line)
				return false;

			return a.Char <= b.Char;
		}

		public static bool operator >(TextPosition a, TextPosition b)
		{
			if (a.Line > b.Line)
				return true;

			if (a.Line < b.Line)
				return false;

			return a.Char > b.Char;
		}

		public static bool operator >=(TextPosition a, TextPosition b)
		{
			if (a.Line > b.Line)
				return true;

			if (a.Line < b.Line)
				return false;

			return a.Char >= b.Char;
		}

		public static TextPosition Min(TextPosition a, TextPosition b)
		{
			return a <= b ? a : b;
		}

		public static TextPosition Max(TextPosition a, TextPosition b)
		{
			return a >= b ? a : b;
		}

		public readonly int Line, Char;

		public TextPosition(int l, int c)
		{
			Line = l;
			Char = c;
		}

		public override bool Equals(object obj)
		{
			if (!(obj is TextPosition))
				return false;

			var other = (TextPosition)obj;
			return
				Line == other.Line &&
				Char == other.Char;
		}

		public override int GetHashCode()
		{
			return Line ^ Char;
		}
	}

	class TextSpan
	{
		public static bool operator ==(TextSpan a, TextSpan b)
		{
			var aNull = ReferenceEquals(a, null);
			var bNull = ReferenceEquals(b, null);

			if (aNull && bNull)
				return true;

			if ((aNull && !bNull) || (!aNull && bNull))
				return false;

			return a.Equals(b);
		}

		public static bool operator !=(TextSpan a, TextSpan b)
		{
			return !(a == b);
		}

		public static bool Intersects(TextSpan a, TextSpan b)
		{
			return !(a.End <= b.Start || a.Start >= b.End);
		}

		public static TextSpan Intersection(TextSpan a, TextSpan b)
		{
			return Intersects(a, b) ?
				new TextSpan(TextPosition.Max(a.Start, b.Start), TextPosition.Min(a.End, b.End)) :
				null;
		}

		public readonly TextPosition Start, End;

		public TextSpan(TextPosition start, TextPosition end)
		{
			bool isValid = start <= end;
			Start = isValid ? start : end;
			End = isValid ? end : start;
		}

		public override bool Equals(object obj)
		{
			if (!(obj is TextSpan))
				return false;

			var other = (TextSpan)obj;
			return
				Start == other.Start &&
				End == other.End;
		}

		public override int GetHashCode()
		{
			return Start.GetHashCode() ^ End.GetHashCode();
		}

		public bool Contains(TextPosition p)
		{
			return p >= Start && p < End;
		}
	}
}
