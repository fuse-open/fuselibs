using Uno;
using Uno.Collections;
using Uno.Testing;
using Fuse;
using FuseTest;
using Fuse.ImageTools;

namespace Fuse.ImageTools.Test
{
	public class ImageToolsTest : TestBase
	{
		private Object _image = null;


		[Test]
		public void AllElementProps()
		{
			var image = new ImageTools.ImageTools();
			using (var root = new TestRootPanel()){
				var future = ImageTools.ImageFromBase64("a4542b");
				future.Then(Print, Fail);
				root.StepFrame();
				root.StepFrame();
				root.StepFrame();
				root.StepFrame();

				Assert.IsNotEqual(_image, null);
			}
		}

		private static void Fail(Exception e)
		{
			debug_log "error" + e;
		}

	    private static void Print(Object image)
	    {
	    	debug_log "stuff: " + image;
	    }

		[Test]
		public void AllLayoutTets()
		{
		}
	}
}
