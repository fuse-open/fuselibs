using Uno;
using Uno.Testing;

using Fuse;
using FuseTest;

namespace Fuse.Test
{
	public class FastMatrixTest : TestBase
	{
		[Test]
		public void Translation()
		{
			var f = FastMatrix.Identity();
			f.PrependTranslation(100,50,25);
			Assert.AreEqual(100,f.Matrix.M41);
		}
	}
}
