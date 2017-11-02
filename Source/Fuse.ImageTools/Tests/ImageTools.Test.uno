using Uno;
using Uno.Collections;
using Uno.Testing;
using Uno.Threading;
using Fuse;
using FuseTest;

namespace Fuse.ImageTools.Test
{
	public class ImageToolsTest : TestBase
	{
		AutoResetEvent _done = new AutoResetEvent(false);
		Object _image = null;

		[Test]
		[Ignore("Only supported on dotnet, Android or iOS", "NATIVE")]
		public void CreatingAnImageSucceeds()
		{
			using (var root = new TestRootPanel()){
				var future = ImageTools.ImageFromBase64("iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPAQMAAAABGAcJAAAABlBMVEX9//wAAQATpOzaAAAAH0l" + "EQVQI12MAAoMHIFLAAYSEwIiJgYGZASrI38AAAwBamgM5VF7xgwAAAABJRU5ErkJggg==");
				future.Then(SaveImage, Fail);
				_done.WaitOne();

				Assert.AreNotEqual(null, _image);
			}
			_image = null;
		}

		void MakeInvalidImage()
		{
			var future = ImageTools.ImageFromBase64("iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPAQMAAAABGAcJAAAABlBMVEX9//wAAQATpOzaAAAAH0l");
			future.Then(SaveImage, Fail);
		}

		[Test]
		[Ignore("Only supported on dotnet, Android or iOS", "NATIVE")]
		public void CreatingAnImageFails()
		{
			Assert.Throws<FormatException>(MakeInvalidImage);
		}

		private void Fail(Exception e)
		{
			_image = null;
			_done.Set();
		}

		private void SaveImage(Object image)
		{
			_image = image;
			_done.Set();
		}
	}
}
