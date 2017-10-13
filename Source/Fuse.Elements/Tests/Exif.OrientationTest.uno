using Uno.IO;
using Uno.Compiler;
using Uno.Testing;
using Fuse.Resources.Exif;

public class OrientationTest
{
	public void AssertImageOrientation(ImageOrientation expected, BundleFile image, [CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0, [CallerMemberName] string memberName = "")
	{
		var bytes = image.ReadAllBytes();
		var orientation = ExifData.FromByteArray(bytes).Orientation;
		Assert.AreEqual(expected, orientation, filePath, lineNumber, memberName);
	}


	[Test]
	[Ignore("Only supported on dotnet, Android or iOS", "MSVC || CMake")]
	public void ImageOrientationsJpgWithoutExif()
	{
		AssertImageOrientation(ImageOrientation.Identity, import("Assets/bird0.jpg"));
		AssertImageOrientation(ImageOrientation.Identity, import("Assets/bird1.jpg"));
		AssertImageOrientation(ImageOrientation.Identity, import("Assets/bird2.jpg"));
		AssertImageOrientation(ImageOrientation.Identity, import("Assets/bird3.jpg"));
	}

	[Test]
	[Ignore("Only supported on dotnet, Android or iOS", "MSVC || CMake")]
	public void ImageOrientationsPng() //pngs do not support exif, so we expect to get ImageOrientation.Identity
	{
		AssertImageOrientation(ImageOrientation.Identity, import("Assets/flower_ref.png"));
		AssertImageOrientation(ImageOrientation.Identity, import("Assets/goat.png"));
		AssertImageOrientation(ImageOrientation.Identity, import("Assets/giraffe.png"));
	}

	[Test]
	[Ignore("Only supported on dotnet, Android or iOS", "MSVC || CMake")]
	public void ImageOrientationsTestSet1()
	{
		AssertImageOrientation(ImageOrientation.Identity, import("Assets/f1t.jpg"));
		AssertImageOrientation(ImageOrientation.FlipVertical | ImageOrientation.Rotate180, import("Assets/f2t.jpg"));
		AssertImageOrientation(ImageOrientation.Rotate180, import("Assets/f3t.jpg"));
		AssertImageOrientation(ImageOrientation.FlipVertical, import("Assets/f4t.jpg"));
		AssertImageOrientation(ImageOrientation.FlipVertical | ImageOrientation.Rotate270, import("Assets/f5t.jpg"));
		AssertImageOrientation(ImageOrientation.Rotate90, import("Assets/f6t.jpg"));
		AssertImageOrientation(ImageOrientation.FlipVertical | ImageOrientation.Rotate90, import("Assets/f7t.jpg"));
		AssertImageOrientation(ImageOrientation.Rotate270, import("Assets/f8t.jpg"));
	}

	[Test]
	[Ignore("Only supported on dotnet, Android or iOS", "MSVC || CMake")]
	public void ImageOrientationsTestSet2()
	{
		AssertImageOrientation(ImageOrientation.Identity, import("Assets/Landscape_1.jpg"));
		AssertImageOrientation(ImageOrientation.FlipVertical | ImageOrientation.Rotate180, import("Assets/Landscape_2.jpg"));
		AssertImageOrientation(ImageOrientation.Rotate180, import("Assets/Landscape_3.jpg"));
		AssertImageOrientation(ImageOrientation.FlipVertical, import("Assets/Landscape_4.jpg"));
		AssertImageOrientation(ImageOrientation.FlipVertical | ImageOrientation.Rotate270, import("Assets/Landscape_5.jpg"));
		AssertImageOrientation(ImageOrientation.Rotate90, import("Assets/Landscape_6.jpg"));
		AssertImageOrientation(ImageOrientation.FlipVertical | ImageOrientation.Rotate90, import("Assets/Landscape_7.jpg"));
		AssertImageOrientation(ImageOrientation.Rotate270, import("Assets/Landscape_8.jpg"));
	}

	[Test]
	[Ignore("Only supported on dotnet, Android or iOS", "MSVC || CMake")]
	public void ImageOrientationsTestSet3()
	{
		AssertImageOrientation(ImageOrientation.Identity, import("Assets/Portrait_1.jpg"));
		AssertImageOrientation(ImageOrientation.FlipVertical | ImageOrientation.Rotate180, import("Assets/Portrait_2.jpg"));
		AssertImageOrientation(ImageOrientation.Rotate180, import("Assets/Portrait_3.jpg"));
		AssertImageOrientation(ImageOrientation.FlipVertical, import("Assets/Portrait_4.jpg"));
		AssertImageOrientation(ImageOrientation.FlipVertical | ImageOrientation.Rotate270, import("Assets/Portrait_5.jpg"));
		AssertImageOrientation(ImageOrientation.Rotate90, import("Assets/Portrait_6.jpg"));
		AssertImageOrientation(ImageOrientation.FlipVertical | ImageOrientation.Rotate90, import("Assets/Portrait_7.jpg"));
		AssertImageOrientation(ImageOrientation.Rotate270, import("Assets/Portrait_8.jpg"));
	}
}
