using Uno;
using Uno.UX;
using Uno.Testing;

using FuseTest;

namespace Fuse.Reactive.Test
{
	public class VectorFunctionsTest : TestBase
	{
		[Test]
		// Note that x,y are actually part of the LayoutFunctions as they are overridden
		public void XYWZ()
		{
			var p = new UX.VectorFunctions.XYZW();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(5,p.xa.Value);
				Assert.AreEqual(6,p.ya.Value);
				Assert.AreEqual(7,p.za.Value);
				Assert.AreEqual(3,p.zb.Value);
				Assert.AreEqual(4,p.wb.Value);
			}
		}
	}

}
