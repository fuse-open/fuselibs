using Uno;
using Uno.Collections;
using Uno.Testing;
using Fuse;
using FuseTest;
using Fuse.ImageTools;

namespace Fuse.Test
{
	public class ImageUtilsTest : TestBase
	{

		[Test]
		public void AllElementProps()
		{
			var future = Fuse.ImageTools.ImageTools.ImageFromBase64("a4542b");
			debug_log "future" + future;
		}

	    private static void Print(string s)
	    {
	    }

		[Test]
		public void AllLayoutTets()
		{
		}
	}
}
