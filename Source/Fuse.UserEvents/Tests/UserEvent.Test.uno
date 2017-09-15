using Uno.Testing;
using FuseTest;
using Fuse.UserEvents;

namespace Fuse.UserEvents.Test
{
	public class UserEventTest : TestBase
	{
		[Test]
		public void UserEventArgs()
		{
			var e = new UX.UserEventArgs();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual("Not Triggered", e.ResultText.Value);

				e.Trigger.Value = true;
				root.StepFrameJS();
				Assert.AreEqual("Triggered", e.ResultText.Value);
			}
		}
	}
}
