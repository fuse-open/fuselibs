using Uno;
using Uno.Testing;

using Fuse.Charting;

using FuseTest;

namespace Fuse.Test
{
	public class DataSeriesTest: TestBase
	{
		[Test]
		public void Basic()
		{
			var p = new UX.DataSeries.Basic();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				var ds = p.P.Series[0].PlotData;
				Assert.AreEqual(3, ds.Count);
				Assert.AreEqual(3, ds[0].Value.Y);
				Assert.AreEqual(1, ds[1].Value.Y);
				Assert.AreEqual(2, ds[2].Value.Y);
				Assert.AreEqual(0.5f, ds[0].Value.X);
				Assert.AreEqual(1.5f, ds[1].Value.X);
				Assert.AreEqual(2.5f, ds[2].Value.X);
				
				ds = p.P.Series[1].PlotData;
				Assert.AreEqual(4, ds.Count);
				Assert.AreEqual(0.5f, ds[0].Value.X); //specified value ignored in Count mode
				Assert.AreEqual(5, ds[0].SourceValue.X);
				Assert.AreEqual(3, ds[1].Value.Y);
				Assert.AreEqual(6, ds[2].Value.Z);
				Assert.AreEqual(1, ds[3].Value.W);
			}
		}
		
		[Test]
		public void Array()
		{
			var p = new UX.DataSeries.Array();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				var ds = p.P.Series[0].PlotData;
				Assert.AreEqual(3,ds.Count);
				Assert.AreEqual(3,ds[0].SourceValue.Y);
				Assert.AreEqual(1,ds[1].SourceValue.Y);
				Assert.AreEqual(2,ds[2].SourceValue.Y);
			}
		}
	}
}