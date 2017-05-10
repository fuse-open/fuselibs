using Uno;
using Uno.Testing;

using Fuse.Internal;
using FuseTest;

namespace Fuse.Test
{
	public class VectorUtilTest : TestBase
	{
		[Test]
		public void Angle()
		{
			Assert.AreEqual( Math.PIf/2, VectorUtil.Angle(float2(1,0),float2(0,1)) );
			Assert.AreEqual( Math.PIf, VectorUtil.Angle(float2(0,-1),float2(0,1)) );
			Assert.AreEqual( 0, VectorUtil.Angle(float2(1,0),float2(1,0)) );
		}
	}
}
