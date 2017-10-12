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
		AssertImageOrientation(ImageOrientation.Identity, import("bird0.jpg"));
		AssertImageOrientation(ImageOrientation.Identity, import("bird1.jpg"));
		AssertImageOrientation(ImageOrientation.Identity, import("bird2.jpg"));
		AssertImageOrientation(ImageOrientation.Identity, import("bird3.jpg"));
	}

	[Test]
	[Ignore("Only supported on dotnet, Android or iOS", "MSVC || CMake")]
	public void ImageOrientationsPng() //pngs do not support exif, so we expect to get ImageOrientation.Identity
	{
		AssertImageOrientation(ImageOrientation.Identity, import("flower_ref.png"));
		AssertImageOrientation(ImageOrientation.Identity, import("goat.png"));
		AssertImageOrientation(ImageOrientation.Identity, import("giraffe.png"));
	}

	[Test]
	[Ignore("Only supported on dotnet, Android or iOS", "MSVC || CMake")]
	public void ImageOrientationsTestSet1()
	{
		AssertImageOrientation(ImageOrientation.Identity, import("f1t.jpg"));
		AssertImageOrientation(ImageOrientation.FlipVertical | ImageOrientation.Rotate180, import("f2t.jpg"));
		AssertImageOrientation(ImageOrientation.Rotate180, import("f3t.jpg"));
		AssertImageOrientation(ImageOrientation.FlipVertical, import("f4t.jpg"));
		AssertImageOrientation(ImageOrientation.FlipVertical | ImageOrientation.Rotate270, import("f5t.jpg"));
		AssertImageOrientation(ImageOrientation.Rotate90, import("f6t.jpg"));
		AssertImageOrientation(ImageOrientation.FlipVertical | ImageOrientation.Rotate90, import("f7t.jpg"));
		AssertImageOrientation(ImageOrientation.Rotate270, import("f8t.jpg"));
	}

	[Test]
	[Ignore("Only supported on dotnet, Android or iOS", "MSVC || CMake")]
	public void ImageOrientationsTestSet2()
	{
		AssertImageOrientation(ImageOrientation.Identity, import("Landscape_1.jpg"));
		AssertImageOrientation(ImageOrientation.FlipVertical | ImageOrientation.Rotate180, import("Landscape_2.jpg"));
		AssertImageOrientation(ImageOrientation.Rotate180, import("Landscape_3.jpg"));
		AssertImageOrientation(ImageOrientation.FlipVertical, import("Landscape_4.jpg"));
		AssertImageOrientation(ImageOrientation.FlipVertical | ImageOrientation.Rotate270, import("Landscape_5.jpg"));
		AssertImageOrientation(ImageOrientation.Rotate90, import("Landscape_6.jpg"));
		AssertImageOrientation(ImageOrientation.FlipVertical | ImageOrientation.Rotate90, import("Landscape_7.jpg"));
		AssertImageOrientation(ImageOrientation.Rotate270, import("Landscape_8.jpg"));
	}

	[Test]
	[Ignore("Only supported on dotnet, Android or iOS", "MSVC || CMake")]
	public void ImageOrientationsTestSet3()
	{
		AssertImageOrientation(ImageOrientation.Identity, import("Portrait_1.jpg"));
		AssertImageOrientation(ImageOrientation.FlipVertical | ImageOrientation.Rotate180, import("Portrait_2.jpg"));
		AssertImageOrientation(ImageOrientation.Rotate180, import("Portrait_3.jpg"));
		AssertImageOrientation(ImageOrientation.FlipVertical, import("Portrait_4.jpg"));
		AssertImageOrientation(ImageOrientation.FlipVertical | ImageOrientation.Rotate270, import("Portrait_5.jpg"));
		AssertImageOrientation(ImageOrientation.Rotate90, import("Portrait_6.jpg"));
		AssertImageOrientation(ImageOrientation.FlipVertical | ImageOrientation.Rotate90, import("Portrait_7.jpg"));
		AssertImageOrientation(ImageOrientation.Rotate270, import("Portrait_8.jpg"));
	}
}
