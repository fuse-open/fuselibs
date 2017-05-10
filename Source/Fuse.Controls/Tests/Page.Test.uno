using Uno;
using Uno.Collections;
using Uno.Testing;
using Fuse;
using Fuse.Controls;
using FuseTest;

namespace Fuse.Test
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

	}
}
