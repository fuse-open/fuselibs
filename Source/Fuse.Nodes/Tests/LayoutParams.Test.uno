using Uno;
using Uno.Testing;

using FuseTest;

namespace Fuse.Test
{
	public class LayoutParamsTest : TestBase
	{
		[Test]
		public void ConstrainMin()
		{
			var lp = LayoutParams.CreateEmpty();
			lp.ConstrainMin( float2(10,0), true, false );
			lp.ConstrainMin( float2(0,5), false, true );
			lp.ConstrainMin( float2(20,2), true, true );
			Assert.AreEqual( float2(20,5), lp.MinSize );
			Assert.IsTrue( lp.HasMinSize );
		}
	}
}
