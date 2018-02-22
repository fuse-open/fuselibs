using Uno;
using Uno.Testing;

using FuseTest;

namespace Fuse.Animations.Test
{
	public class KeyframeTest : TestBase
	{
		[Test]
		public void Expression()
		{
			var p = new UX.Keyframe.Expression();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(300, p.p.Width.Value);
				
				p.t.Pulse();
				root.StepFrame(0.5f);
				Assert.AreEqual(350, p.p.Width.Value, 1e-4);
				root.StepFrame(1f);
				Assert.AreEqual(300, p.p.Width.Value, 1e-4);
			}
		}
	}
}
