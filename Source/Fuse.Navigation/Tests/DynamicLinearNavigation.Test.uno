using Uno;
using Uno.Testing;

using Fuse.Controls;

using FuseTest;

namespace Fuse.Navigation.Test
{
	public class DynamicLinearNavigationTest : TestBase
	{
		[Test]
		public void Active()
		{
			var p = new UX.DynamicLinearNavigation.Active();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(p.one, p.theNav.Active);

				p.theNav.GoBack();
				root.StepFrame(5); //stabilize animiation
				Assert.AreEqual(p.two, p.theNav.Active);

				p.toggleNav.Value = false;
				root.StepFrame();
				p.toggleNav.Value = true;
				root.StepFrame();
				Assert.AreEqual(p.two, p.theNav.Active);

				p.theNav.Active = p.three;
				root.StepFrame(5);
				Assert.AreEqual(p.three, p.theNav.Active);

				p.toggleNav.Value = false;
				root.StepFrame();
				p.theNav.Active = p.four;
				p.toggleNav.Value = true;
				root.StepFrame();
				Assert.AreEqual(p.four, p.theNav.Active);
			}
		}

		[Test]
		public void Basic()
		{
			var p = new UX.DynamicLinearNavigation.Basic();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(p.two, p.theNav.Active);
			}
		}

		[Test]
		public void Index()
		{
			var p = new UX.DynamicLinearNavigation.Index();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual( null, p.theNav.Active );
				//Assert.AreEqual( -1, p.theNav.ActiveIndex ); ???

				p.callAdd.Perform();
				root.StepFrameJS();
				Assert.AreEqual("2", (p.theNav.Active as Text).Value );
			}
		}
	}
}
