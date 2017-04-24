using Uno;
using Uno.Testing;

using Fuse.Internal;
using FuseTest;

namespace Fuse.Test
{
	public class VersionTest : TestBase
	{
		[Test]
		public void BasicParsing()
		{
			Assert.AreEqual(int3(1,2,3), Fuse.Version.Parser.Parse("1.2.3"));
			Assert.AreEqual(int3(1,2,3), Fuse.Version.Parser.Parse("1.2.3-rc.0"));
			Assert.AreEqual(int3(1,2,3), Fuse.Version.Parser.Parse("1.2.3+1337"));

			Assert.AreEqual(int3(10,2,3), Fuse.Version.Parser.Parse("10.2.3"));
			Assert.AreEqual(int3(1,20,3), Fuse.Version.Parser.Parse("1.20.3"));
			Assert.AreEqual(int3(1,2,30), Fuse.Version.Parser.Parse("1.2.30"));
		}
	}
}
