using Uno.Testing;
using Fuse.Resources.Exif;

public class OrientationTest
{
	public void AssertImageOrientation(byte[] bytes, ImageOrientation expected)
	{
		var ori = ExifData.FromByteArray(bytes).Orientation;
		Assert.AreEqual(expected, ori);
	}


	[Test]
	[Ignore("Only supported on dotnet, Android or iOS", "MSVC || CMake")]
	public void ImageOrientationsJpgWithoutExif()
	{
		var f1 = import("bird0.jpg");
		var f2 = import("bird1.jpg");
		var f3 = import("bird2.jpg");
		var f4 = import("bird3.jpg");
		AssertImageOrientation(f1.ReadAllBytes(), ImageOrientation.Identity);
		AssertImageOrientation(f2.ReadAllBytes(), ImageOrientation.Identity);
		AssertImageOrientation(f3.ReadAllBytes(), ImageOrientation.Identity);
		AssertImageOrientation(f4.ReadAllBytes(), ImageOrientation.Identity);
	}

	[Test]
	[Ignore("Only supported on dotnet, Android or iOS", "MSVC || CMake")]
	public void ImageOrientationsPng() //pngs do not support exif, so we expect to get ImageOrientation.Identity
	{
		var f1 = import("flower_ref.png");
		var f2 = import("goat.png");
		var f3 = import("giraffe.png");
		AssertImageOrientation(f1.ReadAllBytes(), ImageOrientation.Identity);
		AssertImageOrientation(f2.ReadAllBytes(), ImageOrientation.Identity);
		AssertImageOrientation(f3.ReadAllBytes(), ImageOrientation.Identity);
	}

	[Test]
	[Ignore("Only supported on dotnet, Android or iOS", "MSVC || CMake")]
	public void ImageOrientationsTestSet1()
	{
		var f1 = import("f1t.jpg");
		var f2 = import("f2t.jpg");
		var f3 = import("f3t.jpg");
		var f4 = import("f4t.jpg");
		var f5 = import("f5t.jpg");
		var f6 = import("f6t.jpg");
		var f7 = import("f7t.jpg");
		var f8 = import("f8t.jpg");
		AssertImageOrientation(f1.ReadAllBytes(), ImageOrientation.Identity);
		AssertImageOrientation(f2.ReadAllBytes(), ImageOrientation.FlipVertical | ImageOrientation.Rotate180);
		AssertImageOrientation(f3.ReadAllBytes(), ImageOrientation.Rotate180);
		AssertImageOrientation(f4.ReadAllBytes(), ImageOrientation.FlipVertical);
		AssertImageOrientation(f5.ReadAllBytes(), ImageOrientation.FlipVertical | ImageOrientation.Rotate270);
		AssertImageOrientation(f6.ReadAllBytes(), ImageOrientation.Rotate90);
		AssertImageOrientation(f7.ReadAllBytes(), ImageOrientation.FlipVertical | ImageOrientation.Rotate90);
		AssertImageOrientation(f8.ReadAllBytes(), ImageOrientation.Rotate270);
	}

	[Test]
	[Ignore("Only supported on dotnet, Android or iOS", "MSVC || CMake")]
	public void ImageOrientationsTestSet2()
	{
		var f1 = import("Landscape_1.jpg");
		var f2 = import("Landscape_2.jpg");
		var f3 = import("Landscape_3.jpg");
		var f4 = import("Landscape_4.jpg");
		var f5 = import("Landscape_5.jpg");
		var f6 = import("Landscape_6.jpg");
		var f7 = import("Landscape_7.jpg");
		var f8 = import("Landscape_8.jpg");
		AssertImageOrientation(f1.ReadAllBytes(), ImageOrientation.Identity);
		AssertImageOrientation(f2.ReadAllBytes(), ImageOrientation.FlipVertical | ImageOrientation.Rotate180);
		AssertImageOrientation(f3.ReadAllBytes(), ImageOrientation.Rotate180);
		AssertImageOrientation(f4.ReadAllBytes(), ImageOrientation.FlipVertical);
		AssertImageOrientation(f5.ReadAllBytes(), ImageOrientation.FlipVertical | ImageOrientation.Rotate270);
		AssertImageOrientation(f6.ReadAllBytes(), ImageOrientation.Rotate90);
		AssertImageOrientation(f7.ReadAllBytes(), ImageOrientation.FlipVertical | ImageOrientation.Rotate90);
		AssertImageOrientation(f8.ReadAllBytes(), ImageOrientation.Rotate270);
	}

	[Test]
	[Ignore("Only supported on dotnet, Android or iOS", "MSVC || CMake")]
	public void ImageOrientationsTestSet3()
	{
		var f1 = import("Portrait_1.jpg");
		var f2 = import("Portrait_2.jpg");
		var f3 = import("Portrait_3.jpg");
		var f4 = import("Portrait_4.jpg");
		var f5 = import("Portrait_5.jpg");
		var f6 = import("Portrait_6.jpg");
		var f7 = import("Portrait_7.jpg");
		var f8 = import("Portrait_8.jpg");
		AssertImageOrientation(f1.ReadAllBytes(), ImageOrientation.Identity);
		AssertImageOrientation(f2.ReadAllBytes(), ImageOrientation.FlipVertical | ImageOrientation.Rotate180);
		AssertImageOrientation(f3.ReadAllBytes(), ImageOrientation.Rotate180);
		AssertImageOrientation(f4.ReadAllBytes(), ImageOrientation.FlipVertical);
		AssertImageOrientation(f5.ReadAllBytes(), ImageOrientation.FlipVertical | ImageOrientation.Rotate270);
		AssertImageOrientation(f6.ReadAllBytes(), ImageOrientation.Rotate90);
		AssertImageOrientation(f7.ReadAllBytes(), ImageOrientation.FlipVertical | ImageOrientation.Rotate90);
		AssertImageOrientation(f8.ReadAllBytes(), ImageOrientation.Rotate270);
	}
}
