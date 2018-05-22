using Uno;
using Uno.Testing;

using FuseTest;

namespace Fuse.Gestures.Test
{
	public class RangeControl2DTest : TestBase
	{
		[Test]
		//a left half-circle control, basic check that all properties work together
		public void CircularBasic()
		{	
			var p = new UX.RangeControl2D.CircularBasic();
			using (var root = TestRootPanel.CreateWithChild(p, int2(100,100)))
			{
				Assert.AreEqual(225, p.crb.DegreesValue);
				
				var a = Math.DegreesToRadians(135.0f);
				var r = 40;
				root.PointerPress( float2(Math.Cos(a),Math.Sin(a))*r + float2(50,50) );
				root.PointerRelease();
				Assert.AreEqual(float2(30,160), p.Value);
				
				//a value outside the range to test clamping.
				a = Math.DegreesToRadians(45.0f);
				r = 15;
				root.PointerPress( float2(Math.Cos(a),Math.Sin(a))*r + float2(50,50) );
				root.PointerRelease();
				Assert.AreEqual(100, p.Value.Y);
				//there's no guarantee at the moment of clamping direction (could be max or min)
				//TODO: https://github.com/fuse-open/fuselibs/issues/798
				Assert.IsTrue( Math.Abs(p.Value.X-0) < 1e-4 ||
					Math.Abs(p.Value.X-120) < 1e-4);
			}
		}
	}
}
