using Uno;
using Uno.Testing;

using Fuse.Triggers;

using FuseTest;

namespace Fuse.Gestures.Test
{
	/* Tests that cover priority resolution and interactions between gestures. These don't really belong on any of the individual gestures. */
	public class GestureTest : TestBase
	{
		[Test]
		public void Layer()
		{	
			var p = new UX.Gesture.Layer();
			using (var root = TestRootPanel.CreateWithChild(p, int2(1000)))
			{
				root.PointerSlide(float2(950,50), float2(850,50), 100);
				root.StepFrame(5);//stabilize
				Assert.AreEqual(p.edgeRight, p.edge.Active);
			}
		}
	}
}
