using Uno;
using Uno.Collections;
using Fuse;
using FuseTest;
using Uno.Testing;
using Fuse.Controls;
using FuseTest;

namespace Fuse.Controls.Test
{
	public class NavigationTest : TestBase
	{
		//BackButton
		
		[Test]
		public void BackButtonAllElementPropertyTests()
		{
			var b = new BackButton();
			ElementPropertyTester.All(b);
		}
		
		[Test]
		public void BackButtonAllLayoutTests()
		{
			var b = new BackButton();
			ElementLayoutTester.All(b);
		}
		
		//NavigationBar
		
		[Test]
		public void NavigationBarAllElementPropertyTests()
		{
			var n = new NavigationBar();
			ElementPropertyTester.All(n);
		}
		
		[Test]
		public void NavigationBarAllElementLayoutTests()
		{
			var n = new NavigationBar();
			ElementLayoutTester.All(n);
		}
		
	}
}
