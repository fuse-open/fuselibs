using Uno;
using Uno.Testing;

using FuseTest;

namespace Fuse.Controls.Test
{
	public class ViewboxTest : TestBase
	{
		[Test]
		public void Basic()
		{
			var p = new UX.ViewboxTest();
			using (var root = TestRootPanel.CreateWithChild(p, int2(400)))
			{
				Assert.AreEqual(float2(1000,800),p.R1.ActualSize);
				Assert.AreEqual(float2(0,40)/p.V1.TestScale,p.R1.ActualPosition);
				Assert.AreEqual(float2(0.4f),p.V1.TestScale);

				Assert.AreEqual(float2(10,20),p.R2.ActualSize);
				Assert.AreEqual(float2(5.0f),p.V2.TestScale);
				Assert.AreEqual(float2(150,0)/p.V2.TestScale,p.R2.ActualPosition);

				Assert.AreEqual(float2(50,100),p.R3.ActualSize);
				Assert.AreEqual(float2(1.0f),p.V3.TestScale);
				Assert.AreEqual(float2(175,150),p.R3.ActualPosition);
			}
		}
		
		//https://github.com/fusetools/fuselibs-private/issues/1506
		[Test]
		public void ContentResize()
		{
			var p = new UX.ViewboxContentResize();
			using (var root = TestRootPanel.CreateWithChild(p, int2(500)))
			{
				Assert.AreEqual(float2(5), p.V1.TestScale);

				p.R1.Width= 200;
				root.UpdateLayout();
				Assert.AreEqual(float2(2.5f),p.V1.TestScale);
			}
		}
	}
}
