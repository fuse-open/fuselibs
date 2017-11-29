using Uno;
using Uno.Collections;

using Fuse.Internal;

namespace Fuse.Drawing
{
	static public class LineMetrics
	{
		static public Rect GetBounds( IList<LineSegment> segments )
		{
			return new LineMetricsImpl().GetBounds(segments);
		}
	}
	
	class LineMetricsImpl
	{
		Rect _bounds;
		bool _hasInit = false;
		float2 _curPos = float2(0);
		
		void AddPoint( float2 pt )
		{
			if (!_hasInit)
			{
				_bounds.Minimum = pt;
				_bounds.Maximum = pt;
				_hasInit = true;
				return;
			}
			
			_bounds.Minimum = Math.Min(_bounds.Minimum, pt);
			_bounds.Maximum = Math.Max(_bounds.Maximum, pt);
		}
		
		void AddRect( Rect r )
		{
			AddPoint(r.Minimum);
			AddPoint(r.Maximum);
		}
		
		public Rect GetBounds( IList<LineSegment> segments )
		{
			for (int i=0; i < segments.Count; ++i)
			{
				var cur = segments[i];
				switch (cur.Type)
				{
					case LineSegmentType.Move:
						_curPos = cur.To;
						//doesn't modify the bounds itself
						break;
						
					case LineSegmentType.Close:
						break;
					
					case LineSegmentType.Straight:
						AddPoint( cur.To );
						AddPoint( _curPos );
						_curPos = cur.To;
						break;
						
					case LineSegmentType.BezierCurve:
						BezierBounds(_curPos, cur.To, cur.A, cur.B );
						_curPos = cur.To;
						break;
						
					case LineSegmentType.EllipticArc:
						EllipticBounds(_curPos, cur);
						_curPos = cur.To;
						break;
				}
			}
			
			return _bounds;
		}
	
		void BezierBounds(float2 s, float2 e, float2 c1, float2 c2)
		{
			var x = BezierMinMax(s.X, c1.X, c2.X, e.X);
			var y = BezierMinMax(s.Y, c1.Y, c2.Y, e.Y);
			
			AddPoint( Curves.CalcBezierAt(s,c1,c2,e,x[0]) );
			AddPoint( Curves.CalcBezierAt(s,c1,c2,e,x[1]) );
			AddPoint( Curves.CalcBezierAt(s,c1,c2,e,y[0]) );
			AddPoint( Curves.CalcBezierAt(s,c1,c2,e,y[1]) );
		}
		
		static float2 BezierMinMax(float p0, float p1, float p2, float p3 )
		{
			//the derivative of he bezier curve is:
			//F'(t) = 3(-(p0-3p1-p3+3p2)*t^2  + 2(p0-2p1+p2)t - p0 + p1)
			//we only care about the zeros, so drop the 3, and replace with simple bits
			//F'(t) = a*t^2 + b*t + c
			var b = 2 * p0 - 4 * p1 + 2 * p2;
			var a = -p0 + 3 * p1 - 3 * p2 + p3;
			var c = p1 - p0;
			//zero points are
			// t = (-b ± sqrt( b^2 - 4ac)) / 2a

			//float precision stuff
			const float zeroTolerance = 1e-05f;
			if (Math.Abs(a) < zeroTolerance)
			{
				if (Math.Abs(b) > zeroTolerance)
				{
					//if -c/b is within 0<t<1 we have a min/max as well
					var cb = -c/b;
					if (cb > 0 && cb < 1) {
						return float2(cb,cb);
					}
				}

				//otherwise the min/max is not within the bounds
				return float2(0,1);
			}
			
			var sqr = b *b - 4 * a * c;
			if (sqr < 0)
				return float2(0,1);
				
			var rt = Math.Sqrt(sqr);
			
			var t1 = (-b + rt) / (2 * a);
			var t2 = (-b - rt) / (2 * a);
			return float2(
				Math.Clamp(t1, 0, 1),
				Math.Clamp(t2, 0, 1) );
		}

		/*
			Calculates the bounds of the ellipse.
			
			It is assumed that calculating this directly on the ellipse is faster than calculating on the bezier approximation. This does however mean it's off by whatever error value that estimation has. In practice this shouldn't be an issue.
		*/
		void EllipticBounds(float2 from, LineSegment seg)
		{
			if (SurfaceUtil.EllipticArcOutOfRange(from,seg))
			{
				AddPoint(from);
				AddPoint(seg.To);
				return;
			}
			
			float2 c, angles;
			var radius = seg.A;
			var xAngle = seg.B.X;
			SurfaceUtil.EndpointToCenterArcParams( from, seg.To, ref radius, xAngle,
				seg.Flags.HasFlag(LineSegmentFlags.EllipticArcLarge), 
				seg.Flags.HasFlag(LineSegmentFlags.EllipticArcSweep),
				out c, out angles );

			var ts = float4(0);
			// solve the derivative of E(t).X == 0
			// tan(t) = - r.Y * sin(xAngle) / (r.X * cos(xAngle))
			ts[0] = Math.Atan2( -radius.Y * Math.Sin(xAngle), radius.X * Math.Cos(xAngle));
			ts[1] = ts[0] + Math.PIf;
			
			// for E(t).Y = 0
			// tan(t) = r.Y * cos(xAngle) / (r.X * sin(xAngle))
			ts[2] = Math.Atan2( radius.Y * Math.Cos(xAngle), radius.X * Math.Sin(xAngle) );
			ts[3] = ts[2] + Math.PIf;
			
			//add any of those extents if they are in the angle range
 			for (int i=0; i < 4; ++i)
 			{
 				var t = ts[i];//i * Math.PIf/2;
 				if (SurfaceUtil.AngleInRange(t, angles[0], angles[0] + angles[1]))
 					AddPoint( SurfaceUtil.EllipticArcPoint( c, radius, xAngle, t ));
 			}
			
			//add both angle end points
			AddPoint( SurfaceUtil.EllipticArcPoint( c, radius, xAngle, angles[0] ) );
			AddPoint( SurfaceUtil.EllipticArcPoint( c, radius, xAngle, angles[0] + angles[1] ) );
		}
	}
	
}
