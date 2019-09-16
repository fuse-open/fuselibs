using Uno;
using Uno.Collections;
using Uno.Testing;
using Uno.UX;

using Fuse.Drawing;

using FuseTest;

namespace Fuse.Test
{
	public class LineParserTest : TestBase
	{
		[Test]
		public void CurveSmooth()
		{
			var list = new LineSegments();
			LineParser.ParseSVGPath( "M100,200 C100,100 250,100 250,200 S400,300 400,200", list.Segments );
			
			Check( list.Segments[0], LineSegmentType.Move, float2(100,200) );
			Check( list.Segments[1], LineSegmentType.BezierCurve, float2(250,200), float2(100,100), float2(250,100) );
			Check( list.Segments[2], LineSegmentType.BezierCurve, float2(400,200), float2(250,300), float2(400,300) );
		}
		
		[Test]
		public void QuadraticCurve()
		{
			var list = new LineSegments();
			LineParser.ParseSVGPath( "M10 80 Q 52.5 10, 95 80 T 180 80", list.Segments );
			
			Assert.AreEqual(3, list.Segments.Count);
			Check( list.Segments[0], LineSegmentType.Move, float2(10,80) );
			Check( list.Segments[1], LineSegmentType.BezierCurve, float2(95,80), 
				float2(38.3333f,33.3333f), float2(66.6666f,33.3333f) );
			Check( list.Segments[2], LineSegmentType.BezierCurve, float2(180,80), 
				float2(123.3333f,126.6666f), float2(151.6666f,126.6666f) );
		}
		
		
		[Test]
		public void PointTokenStart()
		{
			var list = new LineSegments();
			LineParser.ParseSVGPath( "M10 10c0 1.1.9 2 2.2.2", list.Segments );
			
			Assert.AreEqual(2, list.Segments.Count);
			Check( list.Segments[0], LineSegmentType.Move, float2(10,10) );
			Check( list.Segments[1], LineSegmentType.BezierCurve, float2(12.2f,10.2f), 
				float2(10f,11.1f), float2(10.9f, 12f) );
			
			list.Clear();

			LineParser.ParseSVGPath( "M10 10c0.1.2.3.4.5.6", list.Segments );
			
			Assert.AreEqual(2, list.Segments.Count);
			Check( list.Segments[0], LineSegmentType.Move, float2(10,10) );
			Check( list.Segments[1], LineSegmentType.BezierCurve, float2(10.5f,10.6f), 
				float2(10.1f,10.2f), float2(10.3f, 10.4f) );
		}
		
		void Check( LineSegment ls, LineSegmentType type, float2 to )
		{
			Assert.AreEqual( type, ls.Type );
			Assert.AreEqual( to, ls.To );
		}
		
		void Check( LineSegment ls, LineSegmentType type, float2 to, float2 a, float2 b )
		{
			Assert.AreEqual( type, ls.Type );
			Assert.AreEqual( to, ls.To, 1e-4f );
			Assert.AreEqual( a, ls.A, 1e-4f);
			Assert.AreEqual( b, ls.B, 1e-4f );
		}
		
		//for debugging
		void Dump( LineSegments lss )
		{
			debug_log "LineSegments " + lss.Segments.Count;
			foreach ( var ls in lss.Segments ) {
				debug_log ls.Type + " " + ls.Flags + " To:" + ls.To + " A:" + ls.A + " B:" + ls.B;
			}
		}
	}
}
