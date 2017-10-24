using Uno;
using Uno.Collections;
using Uno.Testing;
using Uno.IO;
using Fuse;
using FuseTest;

namespace Fuse.ImageTools.Test
{
	class ImageToolsIntebgrationTest : TestBase
	{

		private Image _image;
		private string _base64;
		private byte[] _bytes;
		private Exception _exception;

		[Test]
		[Ignore("Only supported on dotnet, Android or iOS", "MSVC || CMake")]
		public void ImageFromBase64Succeeds()
		{
			using (var root = new TestRootPanel()){
				var future = ImageTools.ImageFromBase64("iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPAQMAAAABGAcJAAAABlBMVEX9//wAAQATpOzaAAAAH0l" +
																								"EQVQI12MAAoMHIFLAAYSEwIiJgYGZASrI38AAAwBamgM5VF7xgwAAAABJRU5ErkJggg==");
				future.Then(SaveImage, Fail);
			}
			Assert.IsFalse(_image == null);
		}

		[Test]
		[Ignore("Only supported on dotnet, Android or iOS", "MSVC || CMake")]
		public void ImageFromBase64SucceedsIfCorruptedImage()
		{
			using (var root = new TestRootPanel()){
				var future = ImageTools.ImageFromBase64("ss===asdsd");
				future.Then(SaveImage, Fail);
			}
			Assert.IsFalse(_exception == null);
		}

		[Test]
		[Ignore("Only supported on dotnet, Android or iOS", "MSVC || CMake")]
		public void ImageFromBase64SucceedsIfTransparentPng()
		{
			using (var root = new TestRootPanel()){
				var future = ImageTools.ImageFromBase64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==");
				future.Then(SaveImage, Fail);
			}
			Assert.IsFalse(_image == null);
		}

		[Test]
		[Ignore("Only supported on dotnet, Android or iOS", "MSVC || CMake")]
		public void ImageToBase64SucceedsIfJpg()
		{
			using (var root = new TestRootPanel()){
				var img = ImageToolsTestUtils.LoadFromBundle("Assets/jpg.jpg");
				var future = ImageTools.ImageToBase64(img);
				future.Then(TestBase64, Fail);
			}
			Assert.IsFalse(_base64 == null);
		}

		[Test]
		[Ignore("Only supported on dotnet, Android or iOS", "MSVC || CMake")]
		public void ImageToBase64SucceedsIfPng()
		{
			using (var root = new TestRootPanel()){
				var img = ImageToolsTestUtils.LoadFromBundle("Assets/png.png");
				var future = ImageTools.ImageToBase64(img);
				future.Then(TestBase64, Fail);
			}
			Assert.IsFalse(_base64 == null);
		}

		[Test]
		[Ignore("Only supported on dotnet, Android or iOS", "MSVC || CMake")]
		public void BufferFromImageSucceeds()
		{
			using (var root = new TestRootPanel()){
				Image img = ImageToolsTestUtils.LoadFromBundle("Assets/jpg.jpg");
				ImageTools.BufferFromImage(img, SaveBytes, FailString);
			}
			Assert.IsFalse(_bytes == null);
		}

		[Test]
		[Ignore("Only supported on dotnet, Android or iOS", "MSVC || CMake")]
		public void ImageFromByteArrayAsyncSucceeds()
		{
			using (var root = new TestRootPanel()){
				var bytes = ImageToolsTestUtils.LoadBytesFromBundle("Assets/jpg.jpg");
				var future = ImageTools.ImageFromByteArrayAsync(bytes);
				future.Then(SaveImage, Fail);
			}
			Assert.IsFalse(_image == null);
		}

		[Test]
		[Ignore("Only supported on dotnet, Android or iOS", "MSVC || CMake")]
		public void ImageFromByteArrayAsyncFailsForCorruptedBytes()
		{
			using (var root = new TestRootPanel()){
				var bytes = new byte[]{1,2,3};
				var future = ImageTools.ImageFromByteArrayAsync(bytes);
				future.Then(SaveImage, Fail);
			}
			Assert.IsFalse(_exception == null);
		}

		private void FailString(string e)
		{
			_exception = new Exception(e);
		}

		private void Fail(Exception e)
		{
			_exception = e;
		}

		private void SaveImage(Image image)
		{
			_image = image;
		}

		private void SaveBytes(byte[] bytes)
		{
			_bytes = bytes;
		}

		private void TestBase64(string base64)
		{
			_base64 = base64;
		}
	}
}
