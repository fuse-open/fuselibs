using Uno;
using Uno.Collections;
using Fuse;
using Uno.Testing;
using Fuse.Controls;
using FuseTest;
using FuseTest;

namespace Fuse.Controls.Test
{
	public class StatusBarBackgroundTest : TestBase
	{

		[Test]
		public void AllElementProps()
		{
			var s = new TopFrameBackground();
			ElementPropertyTester.All(s);
		}
	}
}
