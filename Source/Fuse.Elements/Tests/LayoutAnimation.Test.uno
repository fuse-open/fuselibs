using Uno;
using Uno.Compiler;
using Uno.Testing;

using FuseTest;

namespace Fuse.Elements.Test
{
	public class LayoutAnimationTest : TestBase
	{
		[Test]
		public void TransitionLayout()
		{
			var p = new global::UX.LayoutAnimation.TransitionLayout();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000)))
			{
				Assert.AreEqual(float2(0,0), p.m.LocalToParent(float2(0,0)));
				Assert.AreEqual(float2(100,100), p.m.ActualSize);
				
				p.s1.Pulse();
				root.StepFrame(); //TODO: in theory PumpDeferred should have been enough here...
				//note these values should be exact. Animation start is intentionally deferred to the next frame
				Assert.AreEqual(float2(800,950), p.m.LocalToParent(float2(0,0)));
				Assert.AreEqual(float2(200,50), p.m.ActualSize);
				
				root.StepFrame(2);
				
				p.s2.Pulse();
				root.StepFrame();
				Assert.AreEqual(float2(0,800), p.m.LocalToParent(float2(0,0)));
				Assert.AreEqual(float2(50,200), p.m.ActualSize);
			}
		}
	}
}
