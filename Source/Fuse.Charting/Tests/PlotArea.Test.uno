using Uno;
using Uno.Testing;

using Fuse.Charting;

using FuseTest;

namespace Fuse.Test
{
	public class PlotAreaTest: TestBase
	{
		[Test]
		public void PlotArea()
		{
			var p = new UX.PlotArea.Basic();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000,500)))
			{
				root.StepFrameJS();
				Assert.AreEqual(5, p.Plot.DataLimit);
				Assert.AreEqual(10,p.Plot.YAxisSteps);
				
				root.Layout(int2(600,900));
				root.PumpDeferred();
				Assert.AreEqual(3, p.Plot.DataLimit);
				Assert.AreEqual(18,p.Plot.YAxisSteps);
			}
			
		}
		
	}
}