using Uno;
using Uno.Collections;

using Fuse.Elements;

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
	}
	
}
