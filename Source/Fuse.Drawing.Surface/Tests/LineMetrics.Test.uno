using Uno;
using Uno.Collections;
using Uno.Testing;
using Uno.UX;

using Fuse.Drawing;
using Fuse.Internal;

using FuseTest;

namespace Fuse.Test
{
	public class LineMetricsTest : TestBase
	{
		float4 n( Rect r)
		{
			return float4(r.Minimum,r.Maximum);
		}
		
		[Test]
		public void Line()
		{
			var list = new LineSegments();
			list.MoveTo(float2(100,50));
			list.LineTo(float2(200,150));
			Assert.AreEqual(float4(100,50,200,150), n(LineMetrics.GetBounds(list.Segments)) );
		}
		
		[Test]
		public void Bezier()
		{
			var list = new LineSegments();
			list.BezierCurveTo( float2(100,100), float2(50,-100), float2(50,200) );
			Assert.AreEqual(float4(0, -20.71068f, 100, 120.710724f), n(LineMetrics.GetBounds(list.Segments)),
				1e-4f);

			list.Clear();
			LineParser.ParseSVGPath( "M100,200 C100,100 250,100 250,200", list.Segments );
			Assert.AreEqual(float4(100, 125, 250, 200), n(LineMetrics.GetBounds(list.Segments)));
			
			list.Clear();
			LineParser.ParseSVGPath( "M0,0 Q 50 20, 100 80", list.Segments );
			Assert.AreEqual(float4(0,0,100,80),  n(LineMetrics.GetBounds(list.Segments)));
			
			list.Clear();
			LineParser.ParseSVGPath( "M10 80 Q 52.5 10, 95 80 T 180 80", list.Segments );
			Assert.AreEqual(float4(10,45,180,115),  n(LineMetrics.GetBounds(list.Segments)));
		}
		
		[Test]
		public void Arc()
		{
			var list = new LineSegments();
			list.MoveTo(float2(100,100));
			list.EllipticArcTo(float2(100,200), float2(100,50), 0, false, false);
			Assert.AreEqual(float4(0, 100, 100, 200), n(LineMetrics.GetBounds(list.Segments)),1e-4f);
		}
		
		[Test]
		public void ArcCircle()
		{
			var list = new LineSegments();
			LineParser.ParseSVGPath( "M 100,0 A 100,100 0 0,1 100,200 A 100,100 0 0,1 100,0 z", list.Segments );
			Assert.AreEqual(float4(0, 0, 200, 200), n(LineMetrics.GetBounds(list.Segments)),1e-4f);
		}
		
		[Test]
		public void ArcRotated()
		{
			var list = new LineSegments();
			LineParser.ParseSVGPath( "M 100,50 " +
				"A 50,25 -45 0 0 50,0" +
				"A 50,25 -135 0 0 0,50" +
				"A 50,25 135 0 0 50,100" +
				"A 50,25 45 0 0 100 50", list.Segments );
			Assert.AreEqual(float4(-30.9016990f, -30.9016990f, 130.9017030f, 130.9017030f),
				n(LineMetrics.GetBounds(list.Segments)), 1e-4f);
		}
		
		[Test]
		public void Triangle()
		{
			var list = new LineSegments();
			LineParser.ParseSVGPath( "M 5,10 20,10 12.5,25 Z", list.Segments );
			Assert.AreEqual(float4(5, 10, 20, 25), n(LineMetrics.GetBounds(list.Segments)),1e-4f);
		}
		
		/**
			This can be used to calculate the bounds of the segments using time iteration. It's very
			slow. The calcualted numbers are likely more precise, but this can be used at first to
			determine if the calculations seem right.
		*/
		static Rect SlowBounds( IList<LineSegment> segs )
		{
			var bounds = new Rect( segs[0].To, float2(0) );
			for ( int i=0; i < segs.Count; ++i)
			{
				var cur = segs[i];
				switch (cur.Type)
				{
					case LineSegmentType.Move:
					case LineSegmentType.Close:
						break;
					
					case LineSegmentType.Straight:
						bounds.Minimum = Math.Min(bounds.Minimum,cur.To);
						bounds.Maximum = Math.Max(bounds.Maximum,cur.To);
						break;
						
					case LineSegmentType.BezierCurve:
						var p0 = i > 0 ? segs[i-1].To : float2(0);
						var p1 = cur.A;
						var p2 = cur.B;
						var p3 = cur.To;
						
						var steps = 10000;
						for (int s =0; s <= steps; ++s )
						{
							var pt = Curves.CalcBezierAt(p0,p1,p2,p3, (float)s / (float)steps );
							bounds.Minimum = Math.Min(bounds.Minimum,pt);
							bounds.Maximum = Math.Max(bounds.Maximum,pt);
						}
						break;
						
					case LineSegmentType.EllipticArc:
					{
						var list = new List<LineSegment>();
						var prev = segs[i-1];
						list.Add( new LineSegment{ Type= LineSegmentType.Move, To = prev.To });
						SurfaceUtil.EllipticArcToBezierCurve( prev.To, cur, list );
						var r = SlowBounds(list);
						bounds.Minimum = Math.Min(bounds.Minimum,r.Minimum);
						bounds.Maximum = Math.Max(bounds.Maximum,r.Maximum);
						break;
					}
				}
			}
			
			return bounds;
		}
	}
}
