using Fuse.Internal;
using Uno;
using Uno.Testing;

using FuseTest;

namespace Fuse.Test
{
	public class CollisionTest : TestBase
	{

		[Test]
		public void LineLineIntersection()
		{
			float2 r;
			Assert.IsTrue( Collision.LineLineIntersection( 
				float2(1), float2(2,1), 
				float2(4,5), float2(-1,5), out r));
			Assert.AreEqual( float2(4.4545f, 2.7272f), r, 1e-4f);
			
			Assert.IsTrue( Collision.LineLineIntersection( 
				float2(0), float2(0,1), 
				float2(-2,-1), float2(1,1), out r));
			Assert.AreEqual( float2(0,1), r, 1e-4f);
			
			Assert.IsFalse( Collision.LineLineIntersection(
				float2(2,4), float2(2,3),
				float2(2,5), float2(2,3), out r ));
				
			Assert.IsTrue( Collision.LineLineIntersection(
				float2(0), float2(1,-1),
				float2(5), float2(1,1), out r ));
			Assert.AreEqual( float2(0), r, 1e-4f );
		}
	}
}
