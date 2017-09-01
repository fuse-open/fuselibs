using Uno;
using Uno.UX;
using Uno.Testing;

using FuseTest;

namespace Fuse.Reactive.Bindings.Test
{
	public class InstanceTest : TestBase
	{
		[Test]
		public void TemplateNodeGroup()
		{
			var p = new UX.Instance.TemplateNodeGroup();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "zero,one,two", GetText(p));
			}
		}
	}
}
