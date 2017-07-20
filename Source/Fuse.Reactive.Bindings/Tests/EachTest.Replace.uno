using Uno;
using Uno.UX;
using Uno.Testing;

using Fuse.Controls;
using Fuse.Elements;
using FuseTest;

namespace Fuse.Reactive.Test
{
	public class EachTestReplace : TestBase
	{
		[Test]
		public void ReplaceWithLess()
		{
			var e = new UX.Each.ReplaceWithLessData();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();

				Assert.AreEqual(360*2+1, e.grid.Children.Count);
				
				e.monthsToMaturitySlider.Value = 12;
				root.StepFrameJS();
				Assert.AreEqual(12*2+1, e.grid.Children.Count);

				e.monthsToMaturitySlider.Value = 100;
				root.StepFrameJS();
				Assert.AreEqual(100*2+1, e.grid.Children.Count);

				e.monthsToMaturitySlider.Value = 200;
				root.StepFrameJS();
				Assert.AreEqual(200*2+1, e.grid.Children.Count);

				e.monthsToMaturitySlider.Value = 50;
				root.StepFrameJS();
				Assert.AreEqual(50*2+1, e.grid.Children.Count);
			}
		}
	}
}
