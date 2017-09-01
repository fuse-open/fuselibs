using Uno;
using Uno.Testing;

using Fuse.Navigation;

using FuseTest;

namespace Fuse.Controls.Test
{
	public class PageTest : TestBase
	{
		[Test]
		public void AllElementProps()
		{
			var p = new Page();
			ElementPropertyTester.All(p);
		}

		[Test]
		public void AllLayoutTets()
		{
			var p = new Page();
			ElementLayoutTester.All(p);
		}

		[Test]
		public void FreezeWhileNavigating()
		{
			var p = new UX.Page.FreezeWhileNavigating();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				p.R.Goto( new Route( "one" ) );

				var pg = p.Nav.FirstChild<Page>();
				var b = pg.FirstChild<FuseTest.BusyControl>();
				
				Assert.IsTrue(pg.IsFrozen);
				Assert.IsFalse(pg.TestHasFreezePrepared);
				root.StepFrame();
				root.TestDraw();
				
				Assert.IsTrue(pg.IsFrozen);
				Assert.IsFalse(pg.TestHasFreezePrepared);
				b.IsBusy = false;
				
				root.StepFrame();
				root.TestDraw();
				Assert.IsTrue(pg.IsFrozen);
				Assert.IsTrue(pg.TestHasFreezePrepared);
				
				root.StepFrame(5); //stabilize
				Assert.IsFalse(pg.IsFrozen);
				Assert.IsFalse(pg.TestHasFreezePrepared);
			}
		}

		[Test]
		public void Title()
		{
			var p = new UX.Page.Title();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual("", p.Page.TitleText.Value);

				p.Page.Title = "Foo";
				Assert.AreEqual("Foo", p.Page.TitleText.Value);

				p.Page.Title = "Bar";
				Assert.AreEqual("Bar", p.Page.TitleText.Value);
			}
		}
	}
}
