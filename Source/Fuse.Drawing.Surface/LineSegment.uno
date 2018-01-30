using Uno;
using Uno.Collections;

using Fuse.Elements;
using Fuse.Internal;

namespace Fuse.Drawing
{
	public enum LineSegmentType
	{
		/** Moves the current position, ending the current sub-shape */
		Move,
		/** A straight line segment */
		Straight,
		/** Cubic bezier, A,B are the first/second control point */
		BezierCurve,
		/** 
			Elliptic arc. A = Radius, B = (rotation, unused) 
			This follows the SVG definition of a elliptical arc curve
		*/
		EllipticArc,
		/** Closes the path. Otherwise it will be left open. */
		Close,
	}
	
	[Flags]
	public enum LineSegmentFlags
	{
		None = 0,
		
		//large-arc-flag from SVG
		EllipticArcLarge = 1 << 0,
		//sweep-flag from SVG
		EllipticArcSweep = 1 << 1,
	}
	
	public struct LineSegment
	{
		public float2 To;
		public float2 A,B;
		public LineSegmentFlags Flags;
		public LineSegmentType Type;
	
		internal string Format()
		{
			return Type + " A:" + A + " B:" + B + " To:" + To + " " + Flags;
		}
		
		public bool HasTo 
		{
			get { return Type != LineSegmentType.Close; }
		}
		
		public void Translate(float2 offset)
		{
			if (Type != LineSegmentType.Close)
				To += offset;
				
			if (Type == LineSegmentType.BezierCurve)
			{
				A += offset;
				B += offset;
			}
		}
		
		public void Scale(float2 factor)
		{
			if (Type != LineSegmentType.Close)
				To *= factor;
				
			if (Type == LineSegmentType.BezierCurve)
			{
				A *= factor;
				B *= factor;
			}
			else if (Type == LineSegmentType.EllipticArc)
			{
				A *= factor;
			}
		}
		
		internal bool IsDrawing
		{
			get { return Type != LineSegmentType.Move && Type != LineSegmentType.Close; }
		}
		
		internal void SplitAtTime( float2 from, float t, out LineSegment left, out LineSegment right )
		{
			switch (Type)
			{
				case LineSegmentType.BezierCurve:
				{
					//TODO: provide optimized version
					var p4 = new float2[]{ from, A, B, To };
					var p3 = deCasteljau( p4, t );
					var p2 = deCasteljau( p3, t );
					var p1 = deCasteljau( p2, t );
					
					left = new LineSegment{ Type = LineSegmentType.BezierCurve,
						A = p3[0], B = p2[0], To = p1[0] };
					right = new LineSegment{ Type = LineSegmentType.BezierCurve,
						A = p2[1], B = p3[2], To = p4[3] };
					break;
				}
				
				case LineSegmentType.Straight:
				{
					left = new LineSegment{ Type = LineSegmentType.Straight, To = Math.Lerp( from, To, t ) };
					right = new LineSegment{ Type = LineSegmentType.Straight, To = To };
					break;
				}
				
				case LineSegmentType.EllipticArc: //expected to be converted to Bezier first (as in LineSplitter)
				default:
					//TODO: some innert default is probably better, source data in splitting may be end-user provided
					throw new Exception( "Unsupported type for splitting: " + Type );
			}
		}
		
		static float2[] deCasteljau( float2[] pts, float t )
		{
			var next = new float2[pts.Length-1];
			for (int i=0; i <pts.Length - 1; ++i) {
				next[i] = Math.Lerp(pts[i],pts[i+1],t);
			}
			return next;
		}
		
		internal float EstimateLength( float2 from )
		{
			switch (Type)
			{
				case LineSegmentType.Straight:
					return Vector.Length( To - from );
				
				case LineSegmentType.BezierCurve:
				{
					var a = Vector.Length( To - from );
					var b = Vector.Length( A - from ) + Vector.Length( B - A ) + Vector.Length( To - B );
					return (a+b)/2;
				}
				
				case LineSegmentType.Move:
				case LineSegmentType.Close:
					return 0;
					
				case LineSegmentType.EllipticArc:
					throw new Exception( "Unsupport type for length: " + Type );
			}
			
			return 0;
		}
		
		//TODO: all these float2 from seem to imply LineSegment's should have be relative to the previous position :(
		internal float2 PointAtTime( float2 from, float t )
		{
			switch (Type)
			{
				case LineSegmentType.Straight:
					return Math.Lerp( from, To, t );
					
				case LineSegmentType.BezierCurve:
					return Curves.CalcBezierAt( from, A, B, To, t );
				
				default:
					return from;
			}
		}
		
		internal float2 DirectionAtTime( float2 from, float t )
		{
			switch (Type)
			{
				case LineSegmentType.Straight:
					return To - from;
					
				case LineSegmentType.BezierCurve:
					return SurfaceUtil.BezierCurveDerivative(from,A,B,To, t);
					
				default:
					return float2(0);
			}
		}
	}
	
}
