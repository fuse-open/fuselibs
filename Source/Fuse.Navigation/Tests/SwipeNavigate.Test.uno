using Uno;
using Uno.Testing;

using FuseTest;

namespace Fuse.Navigation.Test
{
	public class SwipeNavigateTest : TestBase
	{
		[Test]
		public void Active()
		{
			var p = new UX.SwipeNavigate();
			using (var root = TestRootPanel.CreateWithChild(p, int2(1000,500)))
			{
				//these are all distance based page switches (> 0.5)

				//default is Left
				root.PointerSwipe( float2(800,100), float2(100,100), 300 );
				root.StepFrame(5); //stabilize
				Assert.AreEqual(p.P2, p.Nav.Active);

				root.PointerSwipe( float2(200,100), float2(750,100), 10 );
				root.StepFrame(5); //stabilize
				Assert.AreEqual(p.P3, p.Nav.Active);

				//right
				p.Swipe.ForwardDirection = SwipeDirection.Right;
				root.PointerSwipe( float2(800,100), float2(100,100), 300 );
				root.StepFrame(5); //stabilize
				Assert.AreEqual(p.P4, p.Nav.Active);

				root.PointerSwipe( float2(200,100), float2(750,100), 10 );
				root.StepFrame(5); //stabilize
				Assert.AreEqual(p.P3, p.Nav.Active);

				//up
				p.Swipe.ForwardDirection = SwipeDirection.Up;
				root.PointerSwipe( float2(100,400), float2(100,100), 300 );
				root.StepFrame(5); //stabilize
				Assert.AreEqual(p.P2, p.Nav.Active);

				root.PointerSwipe( float2(50,50), float2(50,350), 10 );
				root.StepFrame(5); //stabilize
				Assert.AreEqual(p.P3, p.Nav.Active);

				//down
				p.Swipe.ForwardDirection = SwipeDirection.Down;
				root.PointerSwipe( float2(100,400), float2(100,100), 300 );
				root.StepFrame(5); //stabilize
				Assert.AreEqual(p.P4, p.Nav.Active);

				root.PointerSwipe( float2(50,50), float2(50,350), 10 );
				root.StepFrame(5); //stabilize
				Assert.AreEqual(p.P3, p.Nav.Active);
			}
		}

		[Test]
		public void AllowedDirections()
		{
			var p = new UX.SwipeNavigate();
			using (var root = TestRootPanel.CreateWithChild(p, int2(1000,500)))
			{
				//these are all distance based page switches (> 0.5)

				p.Swipe.AllowedDirections = AllowedNavigationDirections.Forward;
				//allowed
				root.PointerSwipe( float2(800,100), float2(100,100), 300 );
				root.StepFrame(5); //stabilize
				Assert.AreEqual(p.P2, p.Nav.Active);

				//not allowed
				root.PointerSwipe( float2(200,100), float2(750,100), 10 );
				root.StepFrame(5); //stabilize
				Assert.AreEqual(p.P2, p.Nav.Active);

				p.Swipe.AllowedDirections = AllowedNavigationDirections.Backward;
				//not allowed
				root.PointerSwipe( float2(800,100), float2(100,100), 300 );
				root.StepFrame(5); //stabilize
				Assert.AreEqual(p.P2, p.Nav.Active);

				//allowed
				root.PointerSwipe( float2(200,100), float2(750,100), 10 );
				root.StepFrame(5); //stabilize
				Assert.AreEqual(p.P3, p.Nav.Active);
			}
		}
	}
}
