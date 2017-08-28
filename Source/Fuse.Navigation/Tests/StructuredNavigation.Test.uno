using Uno;
using Uno.Compiler;
using Uno.Testing;
using Uno.UX;

using FuseTest;
using Fuse.Navigation;

namespace Fuse.Navigation.Test
{
	class MockStructuredNavigation : StructuredNavigation
	{
		internal MockStructuredNavigation(NavigationStructure mode) : base(mode)
		{
		}
	}

	public class StructuredNavigationTest : TestBase
	{
		[Test]
		public void Issue2435()
		{
			var p = new MockStructuredNavigation(StructuredNavigation.NavigationStructure.Linear);
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				var button = new Fuse.Controls.Button();
				root.Children.Add(button);
				root.IncrementFrame();

				p.Active = button;
				p.Active = null;
			}
		}
	}
}
