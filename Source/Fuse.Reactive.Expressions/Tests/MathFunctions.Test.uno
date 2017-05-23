using Uno;
using Uno.UX;
using Uno.Testing;

using FuseTest;

namespace Fuse.Reactive.Test
{
	public class MathFunctionsTest : TestBase
	{
		[Test]
		public void Mod()
		{
			var p = new UX.MathFunctions.Mod();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(1, p.c.Integer);
				
				p.b.Float = 3.5f;
				root.PumpDeferred();
				Assert.AreEqual(3.0f, p.c.Float);
			}
		}
		
	}
}
