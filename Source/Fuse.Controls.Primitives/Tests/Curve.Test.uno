using Uno;
using Uno.Testing;

using Fuse.Drawing;

using FuseTest;

namespace Fuse.Controls.Primitives.Test
{
	public class CurveTest : TestBase
	{
		[Test]
		[extern(MSVC) Ignore("no surface backend")]
		// uses internal knowledge of how Curve works, order of points, to minimize the testing
		public void Close()
		{
			var p = new UX.Curve.Close();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000,100)))
			{
				var s = p.C.TestLineSegments;
				Assert.AreEqual(4,s.Count);
				Assert.AreEqual(LineSegmentType.BezierCurve, s[3].Type);
				Assert.AreEqual(float2(500,100), s[3].To);
				
				p.C.Close = CurveClose.Auto;
				s = p.C.TestLineSegments;
				Assert.AreEqual(6,s.Count);
				Assert.AreEqual(LineSegmentType.BezierCurve, s[4].Type);
				Assert.AreEqual(LineSegmentType.Close, s[5].Type);
				Assert.AreEqual(float2(500,100), s[3].To);
				Assert.AreEqual(float2(500,50), s[4].To);
				
				p.C.Close = CurveClose.Overlap;
				s = p.C.TestLineSegments;
				//no actual end line is inserted, the backend will do that
				Assert.AreEqual(5,s.Count);
				Assert.AreEqual(LineSegmentType.BezierCurve, s[3].Type);
				Assert.AreEqual(LineSegmentType.Close, s[4].Type);
				Assert.AreEqual(float2(500,100), s[3].To);
			}
		}
		
		[Test]
		[extern(MSVC) Ignore("no surface backend")]
		// Curve requries two points to have any path, this tests that check
		public void MinPoints()
		{
			var p = new UX.Curve.MinPoints();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(0, p.C.TestLineSegments.Count);
			}
		}
	}
}
