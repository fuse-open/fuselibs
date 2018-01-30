using Uno;
using Uno.Collections;

namespace Fuse.Drawing
{
	/**
		A helper class that simplifies the creation of lists of line segments.
	*/
	public class LineSegments
	{
		/** Meant to be read-only: do not modify this list directly. */
		public IList<LineSegment> Segments { get; private set; }
		
		float2 _curPos;

		public LineSegment Last
		{
			get { return Segments[Segments.Count-1]; }
		}
		
		public float2 CurPos
		{
			get { return _curPos; }
		}
		
		public float2 StartPos
		{
			get { return Segments.Count > 0 ? Segments[0].To : float2(0); }
		}
		
		public void Clear()
		{
			Segments.Clear();
			_curPos = float2(0);
		}
		
		public int Count
		{
			get { return Segments.Count; }
		}
		
		public LineSegments()
		{
			Segments = new List<LineSegment>();
			_curPos = float2(0);
		}
		
		public LineSegments(IList<LineSegment> segments)
		{
			Segments = segments;
			if (segments.Count > 0)
				_curPos = segments[segments.Count-1].To;
		}
		
		void Add( LineSegment seg )
		{
			Segments.Add(seg);
			if (seg.HasTo)
				_curPos = seg.To;
		}
		
		public void MoveTo( float2 pt )
		{
			Add( new LineSegment{ Type = LineSegmentType.Move, To = pt });
		}
		
		public void MoveToRel( float2 pt )
		{
			MoveTo( pt + _curPos );
		}
		
		public void LineTo( float2 pt )
		{
			Add( new LineSegment{ Type = LineSegmentType.Straight, To = pt });
		}
		
		public void LineToRel( float2 pt )
		{
			LineTo( pt + _curPos );
		}
		
		public void HorizLineTo( float x )
		{
			LineTo( float2(x, _curPos.Y) );
		}
		
		public void HorizLineToRel( float x )
		{
			LineTo( _curPos + float2(x,0) );
		}
		
		public void VertLineTo( float y)
		{
			LineTo( float2(_curPos.X, y) );
		}
		
		public void VertLineToRel( float y)
		{
			LineTo( _curPos + float2(0,y) );
		}
		
		public void BezierCurveTo( float2 pt, float2 controlA, float2 controlB )
		{
			Add( new LineSegment{ Type = LineSegmentType.BezierCurve, To = pt,
				A = controlA, B = controlB });
		}
		
		public void BezierCurveToRel( float2 pt, float2 controlA, float2 controlB )
		{
			BezierCurveTo( pt + _curPos, controlA + _curPos, controlB + _curPos );
		}

		public void ClosePath()
		{
			Add( new LineSegment{ Type = LineSegmentType.Close } );
		}
		
		public void EllipticArcTo( float2 pt, float2 radius, float xAngle, bool large, bool sweep)
		{
			Add( new LineSegment{ Type = LineSegmentType.EllipticArc, To = pt,
				A = radius, B = float2(xAngle,0), Flags =
					(large ? LineSegmentFlags.EllipticArcLarge : LineSegmentFlags.None) |
					(sweep ? LineSegmentFlags.EllipticArcSweep : LineSegmentFlags.None) } );
		}
		
		public void EllipticArcToRel( float2 pt, float2 radius, float xAngle, bool large, bool sweep)
		{
			EllipticArcTo( pt + _curPos, radius, xAngle, large, sweep );
		}
		
		public void QuadraticCurveTo( float2 pt, float2 control )
		{
			var c1 = _curPos + 2.0f/3.0f * (control - _curPos);
			var c2 = pt + 2.0f/3.0f * (control - pt);
			BezierCurveTo( pt, c1, c2 );
		}
		
		public void QuadraticCurveToRel( float2 pt, float2 control )
		{
			QuadraticCurveTo( pt + _curPos, control + _curPos );
		}
	}
}
