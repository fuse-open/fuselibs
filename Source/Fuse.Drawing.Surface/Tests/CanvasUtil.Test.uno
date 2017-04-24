using Uno;
using Uno.Collections;
using Uno.Testing;
using Uno.UX;

using Fuse.Drawing;
using Fuse.Internal;

using FuseTest;

namespace Fuse.Test
{
	public class SurfaceUtilTest : TestBase
	{
		static float r(float f)
		{
			return Math.DegreesToRadians(f);
		}
		
		[Test]
		public void AngleInRange()
		{
			//basic
			Assert.IsTrue( SurfaceUtil.AngleInRange(0, 0, 1));
			Assert.IsFalse( SurfaceUtil.AngleInRange(0, 1, 2));
			Assert.IsTrue( SurfaceUtil.AngleInRange(0, 1, 0));
			Assert.IsFalse( SurfaceUtil.AngleInRange(0, 2, 1));
			
			//Modded
			Assert.IsTrue( SurfaceUtil.AngleInRange(r(50),r(360+30),r(360+60)));
			Assert.IsFalse( SurfaceUtil.AngleInRange(r(20),r(360+30),r(360+60)));
			Assert.IsFalse( SurfaceUtil.AngleInRange(r(70),r(360+30),r(360+60)));
			
			//wraparound
			Assert.IsTrue(SurfaceUtil.AngleInRange(r(30), r(300), r(400)));
			Assert.IsFalse(SurfaceUtil.AngleInRange(r(50), r(300), r(400)));
		}
	}
}
