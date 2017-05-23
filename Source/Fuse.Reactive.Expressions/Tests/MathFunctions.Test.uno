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
				
				p.a.Float = -9.5f;
				root.PumpDeferred();
				Assert.AreEqual(1f, p.c.Float);
				
				p.b.Float = -3f;
				root.PumpDeferred();
				Assert.AreEqual(-0.5f, p.c.Float);
			}
		}

		[Test]
		public void EvenOdd()
		{
			var p = new UX.MathFunctions.EvenOdd();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.IsTrue(p.b.Boolean);
				Assert.IsFalse(p.c.Boolean);
				
				p.a.Integer = -3;
				root.PumpDeferred();
				Assert.IsFalse(p.b.Boolean);
				Assert.IsTrue(p.c.Boolean);
				
				p.a.Float = 2.6f; //rounds to 3
				root.PumpDeferred();
				Assert.IsFalse(p.b.Boolean);
				Assert.IsTrue(p.c.Boolean);
				
				p.a.Float = -2.3f; //rounds to -2
				root.PumpDeferred();
				Assert.IsTrue(p.b.Boolean);
				Assert.IsFalse(p.c.Boolean);
			}
		}
	}
}
