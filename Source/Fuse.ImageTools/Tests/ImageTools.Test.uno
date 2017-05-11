using Uno;
using Uno.Collections;
using Uno.Testing;
using Fuse;
using FuseTest;

namespace Fuse.ImageTools.Test
{
	public class ImageToolsTest : TestBase
	{
		private Object _image = null;

		[Test]
		[Ignore("Only supported on dotnet", "!DOTNET")]
		public void CreatingAnImageSucceeds()
		{
			Fuse.ImageTools.ImageTools image = new Fuse.ImageTools.ImageTools();
			using (var root = new TestRootPanel()){
				var future = ImageTools.ImageFromBase64("iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPAQMAAAABGAcJAAAABlBMVEX9//wAAQATpOzaAAAAH0l" + "EQVQI12MAAoMHIFLAAYSEwIiJgYGZASrI38AAAwBamgM5VF7xgwAAAABJRU5ErkJggg==");
				future.Then(Print, Fail);
				Assert.IsFalse(_image == null);
			}
			_image = null;
		}

		void MakeInvalidImage()
		{
			Fuse.ImageTools.ImageTools image = new Fuse.ImageTools.ImageTools();
			var future = ImageTools.ImageFromBase64("iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPAQMAAAABGAcJAAAABlBMVEX9//wAAQATpOzaAAAAH0l");
			future.Then(Print, Fail);
		}

		[Test]
		[Ignore("Only supported on dotnet", "!DOTNET")]
		public void CreatingAnImageFails()
		{
			Assert.Throws<FormatException>(MakeInvalidImage);
		}

		private void Fail(Exception e)
		{
			_image = null;
		}

		private void Print(Object image)
		{
			_image = image;
		}
	}
}
