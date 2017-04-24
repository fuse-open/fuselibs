using Uno;
using Uno.Testing;

using Fuse.Drawing;

using FuseTest;

namespace Fuse.Test
{
	public class SurfaceTest : TestBase
	{
		[Test]
		public void EnumChecks()
		{
			//CoreGraphicsSurface (+perhaps others) use the specific in values of enums for simplicity
			Assert.AreEqual( 0, (int)LineCap.Butt );
			Assert.AreEqual( 1, (int)LineCap.Round );
			Assert.AreEqual( 2, (int)LineCap.Square );
			
			Assert.AreEqual( 0, (int)LineJoin.Miter );
			Assert.AreEqual( 1, (int)LineJoin.Round );
			Assert.AreEqual( 2, (int)LineJoin.Bevel );
			
			//TODO: If we supported GetNames on the enum we could ensure the count as well
		}
	}
}
