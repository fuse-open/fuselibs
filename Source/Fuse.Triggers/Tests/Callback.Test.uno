using Uno;
using Uno.Data.Json;
using Uno.Testing;
using Uno.UX;

using Fuse.Controls;

using FuseTest;

namespace Fuse.Test
{
	public class CallbackTest : TestBase
	{
		[Test]
		public void ArgsContainsSender()
		{
			var p = new UX.Callback.ArgsContainsSender();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.PointerPress(float2(1, 1));
				root.PointerRelease();

				root.StepFrameJS();
				Assert.AreEqual("ExpectedSender", p.Sender.Value);
			}
		}
	}
}
