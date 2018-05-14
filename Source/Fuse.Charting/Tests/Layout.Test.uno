using Uno;
using Uno.Testing;

using Fuse.Charting;

using FuseTest;

namespace Fuse.Test
{
	public class LayoutTest: TestBase
	{
		[Test]
		public void Enums()
		{
			Assert.AreEqual( 0, (int)PlotAxisLayoutAxis.X );
			Assert.AreEqual( 1, (int)PlotAxisLayoutAxis.Y );
		}
	}
}