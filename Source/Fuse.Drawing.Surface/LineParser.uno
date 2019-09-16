using Uno;
using Uno.Collections;

namespace Fuse.Drawing
{
	public class LineParser
	{
		public static void ParseSVGPath(string data, IList<LineSegment> segments)
		{
			if (data == null || data.Length == 0)
				return;

			try
			{
				new SVGPathParser(data, segments).Parse();
			}
			catch (Exception ex)
			{
				Fuse.Diagnostics.UserError( "Unsupported SVG Path data", data );
			}
		}
	}
	
	class SVGPathParser
	{
		Token _headToken;
		Token _prevToken;
		Token _token;
		LineSegments _segments;
		bool _tokenHasPoint;
		readonly string _data;

		public SVGPathParser(string data, IList<LineSegment> segments)
		{
			_data = data;
			_segments = new LineSegments(segments);
		}
		
		public void Parse()
		{
			_headToken = new Token(-1, false);
			_prevToken = _headToken.Next = new Token(0, false);
			bool wasExponent = false; //rough fix for https://github.com/Outracks/RealtimeStudio/issues/1313
			_tokenHasPoint = false;
			
			for (int i =0; i<_data.Length; i++)
			{
				var c = _data[i];
				switch (c)
				{
					case '\0':
					case ' ':
					case ',':
						StartNewToken(i-1, i+1);
						break;
					case '-':
						if( !wasExponent )
							StartNewToken(i-1, i);
						break;

					case 'M':
					case 'C':
					case 'S':
					case 'Z':
					case 'L':
					case 'H':
					case 'V':
					case 'm':
					case 'c':
					case 's':
					case 'z':
					case 'l':
					case 'h':
					case 'v':
					case 'a':
					case 'A':
					case 'q':
					case 'Q':
					case 't':
					case 'T':
						StartNewToken(i - 1, i, true);
						StartNewToken(i, i + 1);
						break;
					case '.':
						if (_tokenHasPoint) {
							StartNewToken(i - 1, i);
							_tokenHasPoint = true;
						} else {
							_tokenHasPoint = true;
						}
						break;
				}
				wasExponent = c == 'e' || c == 'E';
			}
			_prevToken.Last = _data.Length-1;

			// remove empty tokens from list
			for (var token = _headToken.Next; token != null; )
			{
				var next = token.Next;
				while (next != null && ((next.Last - next.First) < 0))
					next = next.Next;
				token = token.Next = next;
			}

			// build path
			_token = _headToken.Next;
			char prevCommand = 'z';
			while (_token != null)
			{
				if (!_token.HasAction) // skip garbage between commands
				{
					_token = _token.Next;
					continue;
				}

				var currentCommand = _data[_token.First];
				_token = _token.Next;
				do
				{
					Execute(currentCommand, prevCommand);
					prevCommand = currentCommand;
				}
				while (_token != null && !_token.HasAction);
			}
		}

		float2 _prevControl;
		bool _hasPrevControlC, _hasPrevControlQ;
		bool _hasCurrentPoint;
		void Execute(char c, char prev)
		{
			//implied lineTo following move
			if (prev == 'm' || prev == 'M')
			{
				if (c == 'm')	
					c = 'l';
				else if (c == 'M')
					c = 'L';
			}
			
			if (!_hasCurrentPoint && c != 'm' && c != 'M')
			{
				Fuse.Diagnostics.UserError( "Path data must start with a move 'M' or 'm' operation: " 
					+ _data, this );
				//behavior is undefined at this point (nothing will crash, just may not draw anything valid)
			}
			_hasCurrentPoint = true;
			
			switch (c)
			{
				case 'M': 
					_segments.MoveTo(ReadFloat2());
					break;
				case 'C':
				{
					var a = ReadFloat2();
					var b = ReadFloat2();
					var pt = ReadFloat2();
					_segments.BezierCurveTo(pt, a, b);
					break;
				}
				case 'S':
				{
					var b = ReadFloat2();
					var pt = ReadFloat2();
					var a = _hasPrevControlC ? (_segments.CurPos - _prevControl) + _segments.CurPos : _segments.CurPos;
					_segments.BezierCurveTo(pt, a, b);
					break;
				}
				case 'Z':
					_segments.ClosePath();
					break;
				case 'L': 
					_segments.LineTo(ReadFloat2());
					break;
				case 'H':
					_segments.HorizLineTo(ReadFloat());
					break;
				case 'V':
					_segments.VertLineTo(ReadFloat());
					break;
				case 'A':
				{
					var r = ReadFloat2();
					var xAngle = Math.DegreesToRadians(ReadFloat());
					var large = ReadFloat() != 0;
					var sweep = ReadFloat() != 0;
					var pt = ReadFloat2();
					_segments.EllipticArcTo(pt, r, xAngle, large, sweep);
					break;
				}
				case 'Q':
				{
					var ctl = ReadFloat2();
					var end = ReadFloat2();
					_prevControl = ctl;
					_segments.QuadraticCurveTo(end, ctl);
					break;
				}
				case 'T':
				{
					var ctl = _hasPrevControlQ ? (_segments.CurPos - _prevControl) + _segments.CurPos : _segments.CurPos;
					var end = ReadFloat2();
					_segments.QuadraticCurveTo(end, ctl);
					_prevControl = ctl;
					break;
				}

				case 'm':
					_segments.MoveToRel(ReadFloat2());
					break;
				case 'c':
				{
					var a = ReadFloat2();
					var b = ReadFloat2();
					var pt = ReadFloat2();
					_segments.BezierCurveToRel(pt, a, b);
					break;
				}
				case 's':
				{
					var b = ReadFloat2();
					var pt = ReadFloat2();
					var a = _hasPrevControlC ? -(_prevControl - _segments.CurPos) : float2(0);
					_segments.BezierCurveTo(pt, a, b);
					break;
				}
				case 'z':
					_segments.ClosePath();
					break;
				case 'l': 
					_segments.LineToRel(ReadFloat2());
					break;
				case 'h': 
					_segments.HorizLineToRel(ReadFloat());
					break;
				case 'v': 
					_segments.VertLineToRel(ReadFloat());
					break;
				case 'a':
				{
					var r = ReadFloat2();
					var xAngle = Math.DegreesToRadians(ReadFloat());
					var large = ReadFloat() != 0;
					var sweep = ReadFloat() != 0;
					var pt = ReadFloat2();
					_segments.EllipticArcToRel(pt, r, xAngle, large, sweep);
					break;
				}
				case 'q':
				{
					var ctl = ReadFloat2();
					var end = ReadFloat2();
					_prevControl = ctl + _segments.CurPos;
					_segments.QuadraticCurveToRel(end, ctl);
					break;
				}
				case 't':
				{
					var end = ReadFloat2();
					var ctl = _hasPrevControlQ ? (_segments.CurPos - _prevControl) : float2(0);
					_prevControl = ctl + _segments.CurPos;
					_segments.QuadraticCurveToRel(end,ctl);
					break;
				}
			}
			
			_hasPrevControlC = false;
			_hasPrevControlQ = false;
			
			if (c == 'q' || c == 'Q' || c == 't' || c == 'T')
			{
				//value set in switch
				_hasPrevControlQ = true;
			}
			else if (c == 's' || c =='c' || c == 'S' || c == 'C')
			{
				_prevControl = _segments.Last.B;
				_hasPrevControlC = true;
			}
		}

		void StartNewToken(int prevLastChar, int nextFirstChar, bool hasAction = false)
		{
			_tokenHasPoint = false;
			_prevToken.Last = prevLastChar;
			_prevToken = _prevToken.Next = new Token(nextFirstChar, hasAction);
		}


		float ReadFloat()
		{
			var str = _data.Substring(_token.First, ((_token.Last - _token.First) + 1));
			var res = float.Parse(str);
			_token = _token.Next;
			return res;
		}
		
		float2 ReadFloat2()
		{
			var a = ReadFloat();
			var b = ReadFloat();
			return float2( a, b );
		}
	}

	class Token
	{
		public int First;
		public int Last;
		
		public Token Next;

		public bool HasAction;

		public Token(int first, bool hasAction)
		{
			First = first;
			HasAction = hasAction;
		}
	}
}
