using Uno;
using Uno.Collections;
using Uno.Testing;
using Uno.IO;
using Fuse;
using FuseTest;

namespace Fuse.ImageTools.Test
{
	class ImageToolsTestUtils
	{
		public const string TmpTestImage = "tmpTestImg";

		public static Image LoadFromBundle(string path)
		{
			var bytes = LoadBytesFromBundle(path);
			File.WriteAllBytes(TmpTestImage, bytes);
			return new Image(TmpTestImage);
		}

		public static byte[] LoadBytesFromBundle(string path)
		{
			BundleFile bundleFile;
			if(!TryGetBundleFile(path, out bundleFile))
				Assert.Fail("File Not Found");
			return bundleFile.ReadAllBytes();
		}

		public static bool TryGetBundleFile(string sourcePath, out BundleFile bundleFile)
		{
			bundleFile = null;
			foreach(var bf in Uno.IO.Bundle.AllFiles)
			{
				if(bf.SourcePath == sourcePath)
				{
					bundleFile = bf;
					return true;
				}
			}
			return false;
		}
	}
}
