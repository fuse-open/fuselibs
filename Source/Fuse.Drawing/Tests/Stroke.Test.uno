using Uno;
using Uno.Testing;
using Uno.UX;

using FuseTest;

namespace Fuse.Drawing.Test
{
	public class StrokeTest : TestBase
	{
		[Test]
		public void Issue3217()
		{
			var p = new UX.Issue3217();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
			}
		}
	}
}