using Uno;
using Uno.Testing;
using Uno.UX;
using FuseTest;

namespace Fuse.Views.Test
{
	public class ExportedViewsTest
	{
		[Test]
		public void ExportTest()
		{
			var root = TestRootPanel.CreateWithChild(new Fuse.Views.Test.UX.ExportTest());

			var t = Fuse.ExportedViews.FindTemplate("MyExportedView");
			Assert.AreNotEqual(null, t);

			var view = t.New() as Fuse.Views.Test.UX.MyExportedView;
			Assert.AreNotEqual(null, t);
		}
	}
}