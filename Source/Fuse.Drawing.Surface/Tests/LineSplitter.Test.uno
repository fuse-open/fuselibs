using Uno;
using Uno.Collections;
using Uno.Testing;

using FuseTest;

namespace Fuse.Drawing.Test
{
	public class LineSplitterTest : TestBase
	{
		[Test]
		public void LineDistance()
		{
			var split = Parse( "M0,0 L0,100 L300,100");

			Assert.AreEqual( 0.25f, split.DistanceToTime(1.0f/8));
			Assert.AreEqual( 0.75f, split.DistanceToTime(5.0f/8));
			Assert.AreEqual( 5+0.75f, split.DistanceToTime(5+5.0f/8));
			Assert.AreEqual( 1f, split.DistanceToTime(1));
			Assert.AreEqual( 0f, split.DistanceToTime(0));
		}
		
		[Test]
		public void LineSplit()
		{
			var split = Parse( "M0,0 L0,100 L300,100" );

			var ols = SplitTime( split, 0, 0.75f );
 			Assert.AreEqual( 3, ols.Count );
 			Assert.AreEqual( float2(150,100), ols.CurPos );
 			
 			ols = SplitTime( split, 0.75f, 1.25f );
 			Assert.AreEqual( float2(0,50), ols.CurPos );
 			Assert.AreEqual( float2(150,100), ols.StartPos );
		}
		
		LineSegments SplitTime( LineSplitter ls, float start, float end )
		{
			var olist = new List<LineSegment>();
			ls.SplitTime( start, end, olist );
 			return new LineSegments(olist);
		}
		
		LineSplitter Parse( string path )
		{
			LineSegments ls;
			return Parse( path, out ls );
		}
		
		LineSplitter Parse( string path, out LineSegments list )
		{
			list = new LineSegments();
			LineParser.ParseSVGPath( path, list.Segments );
			return new LineSplitter(list.Segments);
		}
		
		[Test]
		public void Bezier()
		{
			LineSegments ls;
			var split = Parse("M 0,50.000053 C -2.8999972e-5,22.385792 22.385742,0 50,0 77.614258,0 100.00003,22.385792 100,50.000053 99.999973,77.614284 77.614218,100 50,100 l 0,100", out ls);
			
			//for the cirular part
			var radius = 50f;
			var segLen = ls.Segments[1].EstimateLength(ls.StartPos);//Actual: 
			var actualSegLen = 2 * Math.PIf * radius / 4;
			Assert.AreEqual( actualSegLen, segLen, 1 ); //lot's of leeway (large values here, rough estimate)
			
			var wholeArcLen = segLen * 3;
			var lineLen = 100;
			var wholeLen = wholeArcLen + lineLen;
			
			Assert.AreEqual( 0.25f, split.DistanceToTime( segLen / wholeLen ));
			Assert.AreEqual( 0.8f, split.DistanceToTime( (wholeArcLen + lineLen * 0.2f) / wholeLen ) );
		
		
			var sp = SplitTime( split, 0.25f * 0.25f, 0.25f * 0.75f ); //middle section of first arc
			Assert.AreEqual( float2(radius - radius * Math.Cos(Math.PIf/8),
				radius - radius * Math.Sin(Math.PIf/8)), sp.StartPos, 2 ); //rough rnage since an estimate
			Assert.AreEqual( float2(radius - radius * Math.Cos(3*Math.PIf/8),
				radius - radius * Math.Sin(3*Math.PIf/8)), sp.CurPos, 2 ); //rough rnage since an estimate
		}
		
		[Test]
		public void Arc()
		{
			var ls = new LineSegments();
			ls.EllipticArcTo( float2(0,100), float2(100,50), Math.PIf, true, true);
			var split = new LineSplitter(ls.Segments);
			
			Assert.AreEqual( 0.08f, split.DistanceToTime(0.1f), 0.01f );
			Assert.AreEqual( 0.5f, split.DistanceToTime(0.5f) );
			
			var seg = SplitTime( split, 0.25f, 0.5f );
			Assert.AreEqual( float2(100,50), seg.CurPos, 1e-4f ); //expect middle point to be nearly exact
			Assert.AreEqual( float2(70.7106780f, 14.6446690f), seg.StartPos ); //result copied from output
		}
	}
}
