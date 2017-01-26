using FuseTest;
using Fuse.Internal.Bitmaps;
using Uno.IO;
using Uno.Testing;
using Uno.UX;

namespace Fuse.Test
{
	sealed class MemoryFileSource : FileSource
	{
		readonly byte[] _bytes;

		public MemoryFileSource(string path, byte[] bytes) : base(path)
		{
			_bytes = bytes;
		}

		public override Stream OpenRead()
		{
			// TODO: this doesn't work right now, due to a bug in Uno.
			// Should be fixed by this PR:
			// https://github.com/fusetools/uno/pull/985
			// return new MemoryStream(_bytes);

			var stream = new MemoryStream();
			stream.Write(_bytes, 0, _bytes.Length);
			stream.Position = 0;
			return stream;
		}
	}

	public class BitmapTest : TestBase
	{
		FileSource CreateBundleFileSource(string fileName)
		{
			var bundle = Bundle.Get();
			var bundleFile = bundle.GetFile(fileName);
			return new BundleFileSource(bundleFile);
		}

		[Test]
		public void BasicPng()
		{
			var basicPng = Bitmap.LoadFromFileSource(CreateBundleFileSource("Assets/basic.png"));
			Assert.AreNotEqual(null, basicPng);
			Assert.AreEqual(3, basicPng.Size.X);
			Assert.AreEqual(2, basicPng.Size.Y);
			float eps = 1.0f / 255;
			Assert.AreEqual(new float4(1, 0, 0, 1), basicPng.GetPixel(0, 0), eps);
			Assert.AreEqual(new float4(0, 1, 0, 1), basicPng.GetPixel(1, 0), eps);
			Assert.AreEqual(new float4(0, 0, 1, 1), basicPng.GetPixel(2, 0), eps);
			Assert.AreEqual(new float4(0, 0, 1, 0.5f), basicPng.GetPixel(0, 1), eps);
			Assert.AreEqual(new float4(0, 1, 0, 0.5f), basicPng.GetPixel(1, 1), eps);
			Assert.AreEqual(new float4(1, 0, 0, 0.5f), basicPng.GetPixel(2, 1), eps);
		}

		[Test]
		public void BasicJpeg()
		{
			var basicJpg = Bitmap.LoadFromFileSource(CreateBundleFileSource("Assets/basic.jpg"));
			Assert.AreNotEqual(null, basicJpg);
			Assert.AreEqual(3, basicJpg.Size.X);
			Assert.AreEqual(2, basicJpg.Size.Y);

			float eps = 15.0f / 255; // JPEG is a bit more lossy
			Assert.AreEqual(new float4(1, 0, 0, 1), basicJpg.GetPixel(0, 0), eps);
			Assert.AreEqual(new float4(0, 1, 0, 1), basicJpg.GetPixel(1, 0), eps);
			Assert.AreEqual(new float4(0, 0, 1, 1), basicJpg.GetPixel(2, 0), eps);
			Assert.AreEqual(new float4(0, 0, 1, 1), basicJpg.GetPixel(0, 1), eps);
			Assert.AreEqual(new float4(0, 1, 0, 1), basicJpg.GetPixel(1, 1), eps);
			Assert.AreEqual(new float4(1, 0, 0, 1), basicJpg.GetPixel(2, 1), eps);

		}

		FileSource CreateMemoryFileSource(string fileName)
		{
			var bundle = Bundle.Get();
			var bundleFile = bundle.GetFile(fileName);
			return new MemoryFileSource(fileName, bundleFile.ReadAllBytes());
		}

		[Test]
		public void FromMemoryFileSource()
		{
			var basicPng = Bitmap.LoadFromFileSource(CreateMemoryFileSource("Assets/basic.png"));
			Assert.AreNotEqual(null, basicPng);
			Assert.AreEqual(3, basicPng.Size.X);
			Assert.AreEqual(2, basicPng.Size.Y);
		}


		[Test]
		public void CmykJPG()
		{
			var cmykJpg = Bitmap.LoadFromFileSource(CreateBundleFileSource("Assets/cmyk.jpg"));
			Assert.AreNotEqual(null, cmykJpg);
			Assert.AreEqual(3, cmykJpg.Size.X);
			Assert.AreEqual(2, cmykJpg.Size.Y);

			float eps = 15.0f / 255; // JPEG is a bit more lossy
			Assert.AreEqual(new float4(1, 0, 0, 1), cmykJpg.GetPixel(0, 0), eps);
			Assert.AreEqual(new float4(0, 1, 0, 1), cmykJpg.GetPixel(1, 0), eps);
			Assert.AreEqual(new float4(0, 0, 1, 1), cmykJpg.GetPixel(2, 0), eps);
			Assert.AreEqual(new float4(0, 0, 1, 1), cmykJpg.GetPixel(0, 1), eps);
			Assert.AreEqual(new float4(0, 1, 0, 1), cmykJpg.GetPixel(1, 1), eps);
			Assert.AreEqual(new float4(1, 0, 0, 1), cmykJpg.GetPixel(2, 1), eps);

		}
	}
}
