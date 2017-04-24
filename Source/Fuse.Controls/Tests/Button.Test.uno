using Uno;
using Uno.Collections;
using Uno.Testing;
using Fuse;
using Fuse.Controls;
using FuseTest;

namespace Fuse.Test
{
	public class ButtonTest : TestBase
	{
		[Test]
		public void AllElementProps()
		{
			var e = new Button();
			ElementPropertyTester.All(e);
		}

		[Test]
		public void AllLayoutTets()
		{
			var b = new Button();
			ElementLayoutTester.All(b);
		}
	}
}
