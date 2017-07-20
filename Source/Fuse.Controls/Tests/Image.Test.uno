using Uno;
using Uno.Collections;
using Uno.Testing;
using Fuse;
using FuseTest;
using Fuse.Elements;
using Fuse.Controls;
using FuseTest;

namespace Fuse.Controls.Test
{
	public class ImageTest : TestBase
	{
		[Test]
		public void AllElementProps()
		{
			var p = new Image();
			ElementPropertyTester.All(p);
		}

		[Test]
		public void AllElementLayoutTest()
		{
			var p = new Image();
			ElementLayoutTester.All(p);
		}
	}
}
