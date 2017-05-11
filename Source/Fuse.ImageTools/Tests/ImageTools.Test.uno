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
		public void CreatingAnImageSucceeds()
		{
			if defined(!DOTNET) return;

			Fuse.ImageTools.ImageTools image = new Fuse.ImageTools.ImageTools();
			using (var root = new TestRootPanel()){
				var future = ImageTools.ImageFromBase64("iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPAQMAAAABGAcJAAAABlBMVEX9//wAAQATpOzaAAAAH0l" + "EQVQI12MAAoMHIFLAAYSEwIiJgYGZASrI38AAAwBamgM5VF7xgwAAAABJRU5ErkJggg==");
				future.Then(Print, Fail);
				root.StepFrame();
				root.StepFrame();
				root.StepFrame();
				root.StepFrame();

				Assert.IsFalse(_image == null);
			}
			_image = null;
		}

		[Test]
		public void CreatingAnImageFails()
		{
			if defined(!DOTNET) return;
			
			Fuse.ImageTools.ImageTools image = new Fuse.ImageTools.ImageTools();
			using (var root = new TestRootPanel()){
				try 
				{
					var future = ImageTools.ImageFromBase64("iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPAQMAAAABGAcJAAAABlBMVEX9//wAAQATpOzaAAAAH0l");
					future.Then(Print, Fail);
				} catch (FormatException e)
				{
					// expected error case
				}
				root.StepFrame();
				root.StepFrame();
				root.StepFrame();
				root.StepFrame();

				Assert.IsTrue(_image == null);
			}
			_image = null;
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
