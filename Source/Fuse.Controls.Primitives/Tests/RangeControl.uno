using Uno;
using Uno.Testing;

using FuseTest;

namespace Fuse.Gestures.Test
{
	public class RangeControlTests : TestBase
	{
		[Test]
		public void Orientation()
		{	
			var p = new UX.RangeControlHorizontal();
			using (var root = TestRootPanel.CreateWithChild(p, int2(1000,500)))
			{
				//note the distance is irrelevant so long as the threshold is exceeded, the final location matters
				root.PointerSwipe( float2(100,100), float2(250,100) );
				Assert.AreEqual( 25, p.Value );
				//back
				root.PointerSwipe( float2(700,200), float2(650,200) );
				Assert.AreEqual( 65, p.Value );

				p.LRB.Orientation = Fuse.Layouts.Orientation.Vertical;
				root.PointerSwipe( float2(100,100), float2(100,250) );
				Assert.AreEqual( 50, p.Value );

				root.PointerSwipe( float2(300,450), float2(300,400) );
				Assert.AreEqual( 80, p.Value );
			}
		}
	}
}
