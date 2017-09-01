using Uno;
using Uno.Compiler;
using Uno.Testing;

using FuseTest;

namespace Fuse.Elements.Test
{
	public class LimitSizingTest : TestBase
	{
		[Test]
		public void Basic()
		{
			var p = new global::UX.LimitSizing();
			using (var root = TestRootPanel.CreateWithChild(p, int2(1000)))
			{
				Assert.AreEqual(float2(100,80),p.R1.ActualSize);
				Assert.AreEqual(float2(100,50),p.L1.ActualSize);

				Assert.AreEqual(float2(80,100),p.R2.ActualSize);
				Assert.AreEqual(float2(50,100),p.L2.ActualSize);
			}
		}
	}
}
