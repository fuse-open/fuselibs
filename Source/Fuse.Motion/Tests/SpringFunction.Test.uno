using Uno;
using Uno.Testing;
using FuseTest;

namespace Fuse.Motion.Simulation.Test
{
	public class SpringFunctionTest : TestBase
	{
		[Test]
		public void AndroidRelease()
		{
			var p = new UX.SpringFunction();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(1.0, p.Output.Value);
				Assert.AreEqual(0.5, p.Constant.Value);

				p.Input.Value = 0.5;
				root.IncrementFrame(1);
				Assert.AreEqual(0.25, p.Output.Value, 0.01);
				Assert.AreEqual(0.5, p.Constant.Value);
			}
		}
	}
}
