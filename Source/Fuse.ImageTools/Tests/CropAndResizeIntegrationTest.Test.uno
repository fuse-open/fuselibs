using Uno;
using Uno.Collections;
using Uno.Testing;
using Uno.IO;
using Fuse;
using FuseTest;

namespace Fuse.ImageTools.Test
{
	public class CropAndResizeIntegrationTest : TestBase
	{

		private Exception _exception;
		private const int _expectedWidth = 10;
		private const int _expectedHeight = 10;
		private int _actualWidth;
		private int _actualHeight;
		private string _actualPath;

		[Test]
		[Ignore("Only supported on dotnet, Android or iOS", "MSVC || CMake")]
		public void ImageResizedToTheSameSize()
		{
			TestImageResize("Assets/jpg.jpg", "jpg", _expectedWidth, _expectedHeight, ResizeMode.IgnoreAspect);
			Assert.IsTrue(_exception == null);
			TestImageResize("Assets/jpg.jpg", "jpg", _expectedWidth, _expectedHeight, ResizeMode.KeepAspect);
			Assert.IsTrue(_exception == null);
			TestImageResize("Assets/jpg.jpg", "jpg", _expectedWidth, _expectedHeight, ResizeMode.ScaleAndCrop);
			Assert.IsTrue(_exception == null);
		}

		[Test]
		[Ignore("Only supported on dotnet, Android or iOS", "MSVC || CMake")]
		public void ImageResizedToBiggerSize()
		{
			TestImageResize("Assets/jpg.jpg", "jpg", _expectedWidth+1, _expectedHeight, ResizeMode.IgnoreAspect,_expectedWidth+1, _expectedHeight, false);
			Assert.IsTrue(_exception == null);
			TestImageResize("Assets/jpg.jpg", "jpg", _expectedWidth+1, _expectedHeight, ResizeMode.KeepAspect, _expectedWidth, _expectedHeight, false);
			Assert.IsTrue(_exception == null);
			TestImageResize("Assets/jpg.jpg", "jpg", _expectedWidth+1, _expectedHeight, ResizeMode.ScaleAndCrop, _expectedWidth, _expectedHeight);
			Assert.IsTrue(_exception == null);

			TestImageResize("Assets/png.png", "png", _expectedWidth, _expectedHeight+1, ResizeMode.IgnoreAspect);
			Assert.IsTrue(_exception == null);
			TestImageResize("Assets/png.png", "png", _expectedWidth, _expectedHeight+1, ResizeMode.KeepAspect, _expectedWidth, _expectedHeight);
			Assert.IsTrue(_exception == null);
			TestImageResize("Assets/png.png", "png", _expectedWidth, _expectedHeight+1, ResizeMode.ScaleAndCrop, _expectedWidth, _expectedHeight);
			Assert.IsTrue(_exception == null);

			TestImageResize("Assets/jpg.jpg", "jpg", _expectedWidth+1, _expectedHeight+1, ResizeMode.IgnoreAspect);
			Assert.IsTrue(_exception == null);
			TestImageResize("Assets/jpg.jpg", "jpg", _expectedWidth+1, _expectedHeight+1, ResizeMode.KeepAspect, _expectedWidth,  _expectedHeight);
			Assert.IsTrue(_exception == null);
			TestImageResize("Assets/jpg.jpg", "jpg", _expectedWidth+1, _expectedHeight+1, ResizeMode.ScaleAndCrop, _expectedWidth, _expectedHeight);
			Assert.IsTrue(_exception == null);
		}

		[Test]
		[Ignore("Only supported on dotnet, Android or iOS", "MSVC || CMake")]
		public void ImageResizedToSmallerSize()
		{
			TestImageResize("Assets/jpg.jpg", "jpg", _expectedWidth-1, _expectedHeight, ResizeMode.IgnoreAspect);
			Assert.IsTrue(_exception == null);
			TestImageResize("Assets/jpg.jpg", "jpg", _expectedWidth-1, _expectedHeight, ResizeMode.KeepAspect, _expectedWidth-1, _expectedHeight-1);
			Assert.IsTrue(_exception == null);
			TestImageResize("Assets/jpg.jpg", "jpg", _expectedWidth-1, _expectedHeight, ResizeMode.ScaleAndCrop, _expectedWidth-1, _expectedHeight-1);
			Assert.IsTrue(_exception == null);

			TestImageResize("Assets/jpg.jpg", "jpg", _expectedWidth, _expectedHeight-1, ResizeMode.IgnoreAspect);
			Assert.IsTrue(_exception == null);
			TestImageResize("Assets/jpg.jpg", "jpg", _expectedWidth, _expectedHeight-1, ResizeMode.KeepAspect, _expectedWidth-1, _expectedHeight-1);
			Assert.IsTrue(_exception == null);
			TestImageResize("Assets/jpg.jpg", "jpg", _expectedWidth, _expectedHeight-1, ResizeMode.ScaleAndCrop, _expectedWidth-1, _expectedHeight-1);
			Assert.IsTrue(_exception == null);

			TestImageResize("Assets/jpg.jpg", "jpg", _expectedWidth-1, _expectedHeight-1, ResizeMode.IgnoreAspect);
			Assert.IsTrue(_exception == null);
			TestImageResize("Assets/jpg.jpg", "jpg", _expectedWidth-1, _expectedHeight-1, ResizeMode.KeepAspect, _expectedWidth-1,  _expectedHeight-1);
			Assert.IsTrue(_exception == null);
			TestImageResize("Assets/jpg.jpg", "jpg", _expectedWidth-1, _expectedHeight-1, ResizeMode.ScaleAndCrop, _expectedWidth-1, _expectedHeight-1);
			Assert.IsTrue(_exception == null);
		}

		[Test]
		[Ignore("Only supported on dotnet, Android or iOS", "MSVC || CMake")]
		public void ImageResizedPerformInPlace()
		{
			var path = "Assets/png.png";
			TestImageResize(path, "png", _expectedWidth-1, _expectedHeight-1, ResizeMode.IgnoreAspect, _expectedWidth-1, _expectedHeight-1, false);
			using (var root = new TestRootPanel())
			{
				Assert.AreNotEqual(path, _actualPath);

				var tmpPath = _actualPath;
				TestImageResize(_actualPath, _expectedWidth-1, _expectedHeight-1, ResizeMode.IgnoreAspect, _expectedWidth-1, _expectedHeight-1, true);
				Assert.AreEqual(tmpPath, _actualPath);
			}
		}

		[Test]
		[Ignore("Only supported on dotnet, Android or iOS", "MSVC || CMake")]
		public void ImageCropIsWorking()
		{
			var path = "Assets/jpg.jpg";
			TestImageCrop(path, "jpg", 1, 1, _expectedWidth-2, _expectedHeight-2, false);
			using (var root = new TestRootPanel())
			{
				Assert.AreNotEqual(path, _actualPath);

				var tmpPath = _actualPath;
				TestImageCrop(tmpPath, 1, 1, _expectedWidth-2, _expectedHeight-2, true);
				Assert.AreEqual(tmpPath, _actualPath);
			}
		}

		private void TestImageResize(string path, int desiredWidth, int desiredHeight, ResizeMode resizeMode,
																int expectedWidth = -1, int expectedHeight = -1, bool inPlace = false)
		{
			using (var root = new TestRootPanel())
			{
				debug_log("desiredWidth " + desiredWidth + ", desiredHeight " + desiredHeight + ", resizeMode " + resizeMode);
				var img = new Image(path);
				var future = ImageTools.Resize(img, desiredWidth, desiredHeight, resizeMode, inPlace);
				future.Then(ExpectedHeightAndWidth, Fail);
			}
			if (expectedWidth == -1) expectedWidth = desiredWidth;
			if (expectedHeight == -1) expectedHeight = desiredHeight;
			Assert.AreEqual(expectedWidth, _actualWidth);
			Assert.AreEqual(expectedHeight, _actualHeight);
		}

		private void TestImageResize(string path, string extension, int desiredWidth, int desiredHeight, ResizeMode resizeMode,
																int expectedWidth = -1, int expectedHeight = -1, bool inPlace = false)
		{
			BundleFile bundleFile;
			if(!ImageToolsTestUtils.TryGetBundleFile(path, out bundleFile))
				Assert.Fail("File Not Found");
			var bytes = bundleFile.ReadAllBytes();
			var tmpPath = ImageToolsTestUtils.RandomFile() + "." + extension;
			File.WriteAllBytes(tmpPath, bytes);
			TestImageResize(tmpPath, desiredWidth, desiredHeight, resizeMode, expectedWidth, expectedHeight, inPlace);
		}

		private void TestImageCrop(string path, int x, int y,
																int width, int height, bool inPlace)
		{
			using (var root = new TestRootPanel())
			{
				debug_log("x " + x + ", y " + y + ", width " + width + ", height " + height);
				var img = new Image(path);
				var future = ImageTools.Crop(img, width, height, x, y, inPlace);
				future.Then(ExpectedHeightAndWidth, Fail);
			}
			Assert.AreEqual(width, _actualWidth);
			Assert.AreEqual(height, _actualHeight);
		}

		private void TestImageCrop(string path, string extension, int x, int y,
																int width, int height, bool inPlace)
		{
			BundleFile bundleFile;
			if(!ImageToolsTestUtils.TryGetBundleFile(path, out bundleFile))
				Assert.Fail("File Not Found");
			var bytes = bundleFile.ReadAllBytes();
			var tmpPath = ImageToolsTestUtils.RandomFile() + "." + extension;
			File.WriteAllBytes(tmpPath, bytes);
			TestImageCrop(tmpPath, x, y, width, height, inPlace);
		}

		private void Fail(Exception e)
		{
			_exception = e;
			debug_log(e.Message);
		}

		public void ExpectedHeightAndWidth(Image newImage)
		{
				_actualWidth = newImage.Width;
				_actualHeight = newImage.Height;
				_actualPath = newImage.Path;
		}
	}
}
