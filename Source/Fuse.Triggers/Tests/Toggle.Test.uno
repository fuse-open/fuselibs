using Uno;
using Uno.Collections;
using Uno.Testing;

using Fuse.Controls;

using FuseTest;

namespace Fuse.Triggers.Test
{
	public class Toggle : TestBase
	{
		[Test]
		public void Basic()
		{
			var p = new UX.Toggle.Basic();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.IsFalse(p.v.Value);
				
				p.t2.Pulse();
				root.PumpDeferred();
				Assert.IsTrue(p.v.Value);
				
				p.t1.Pulse();
				root.PumpDeferred();
				Assert.IsFalse(p.v.Value);
			}
		}
	}
}