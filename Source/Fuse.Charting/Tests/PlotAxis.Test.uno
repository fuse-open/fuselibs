using Uno;
using Uno.Testing;

using Fuse.Charting;
using Fuse.Controls;

using FuseTest;

namespace Fuse.Charting.Test
{
	public class PlotAxisTest: TestBase
	{
		[Test]
		public void Basic()
		{
			var p = new UX.PlotAxis.Basic();
			using (var root = TestRootPanel.CreateWithChild(p,int2(500,1000)))
			{
				root.StepFrameJS();
				Assert.AreEqual( "one,two,three,four,five", Util.GetText(p.XL) );
				Assert.AreEqual( float2(500,20), p.XL.ActualSize );
				
				Assert.AreEqual( "0,10,20,30,40,50,60", Util.GetText(p.YL) );
				Assert.AreEqual( float2(100,1000), p.YL.ActualSize );
			}
		}
		
		[Test]
		public void Group()
		{
			var p = new UX.PlotAxis.Group();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000)))
			{
				root.StepFrameJS();
				Assert.AreEqual( "4,6,8,10,12", Util.GetText(p.XL));
				var txts = Util.Children<Text>(p.XL);
				// ((Index - Offset) + tickOffset) * (stepRange)
				Assert.AreEqual( ((4-3)+0.5f)*(1000/10), txts[0].ActualPosition.X );
				Assert.AreEqual( ((6-3)+0.5f)*(1000/10), txts[1].ActualPosition.X );

				p.XL.ExcludeExtend = false;
				root.StepFrame();
				Assert.AreEqual( "2,4,6,8,10,12", Util.GetText(p.XL));
				txts = Util.Children<Text>(p.XL);
				Assert.AreEqual( ((2-3)+0.5f)*(1000/10), txts[0].ActualPosition.X );
				Assert.AreEqual( ((4-3)+0.5f)*(1000/10), txts[1].ActualPosition.X );

				p.XL.ExcludeExtend = true;
				p.P.DataOffset = 2;
				root.StepFrame();
				Assert.AreEqual( "2,4,6,8,10", Util.GetText(p.XL));
				txts = Util.Children<Text>(p.XL);
				Assert.AreEqual( ((2-2)+0.5f)*(1000/10), txts[0].ActualPosition.X );
				Assert.AreEqual( ((4-2)+0.5f)*(1000/10), txts[1].ActualPosition.X );
				
				p.XL.Group = 3;
				p.P.DataOffset = 1;
				root.StepFrame();
				Assert.AreEqual( "3,6,9", Util.GetText(p.XL));
				txts = Util.Children<Text>(p.XL);
				Assert.AreEqual( ((3-1)+0.5f)*(1000/10), txts[0].ActualPosition.X );
				
				//https://github.com/fusetools/premiumlibs/issues/28
				p.P.DataOffset = 2;
				root.StepFrame();
				Assert.AreEqual( "3,6,9", Util.GetText(p.XL));
				txts = Util.Children<Text>(p.XL);
				Assert.AreEqual( ((3-2)+0.5f)*(1000/10), txts[0].ActualPosition.X );
			}
		}
		
		[Test]
		public void Skip()
		{
			var p = new UX.PlotAxis.Skip();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual("6,7,8,9,10,11,12", Util.GetText(p.XL));
				Assert.AreEqual("6,8,10,12", Util.GetText(p.XM));
				Assert.AreEqual("8,9,10,11,12", Util.GetText(p.XN));
			}
		}
		
		[Test]
		public void Object()
		{
			var p = new UX.PlotAxis.Object();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual("one,two,three,four,five", Util.GetText(p.X));
			}
		}
		
		[Test]
		public void ScreenIndex()
		{
			var p = new UX.PlotAxis.ScreenIndex();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual("0,1,2,3", Util.GetText(p.X));
				
				p.P.DataOffset = 0;
				root.StepFrame();
				Assert.AreEqual("0,1,2,3", Util.GetText(p.X)); //no difference since "screenIndex"
			}
		}
		
		[Test]
		//adapted from Plot.Data.Filter test to see combination with group
		public void FilterGroup()
		{
			var p = new UX.PlotAxis.FilterGroup();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual("3,6", GetText(p.A));
				
				p.D.ExcludeExtend = true;
				root.PumpDeferred();
				Assert.AreEqual("3,6", GetText(p.A));
				
				p.D.SkipEnds = int2(2,1);
				root.PumpDeferred();
				Assert.AreEqual("6", GetText(p.A));
				
				p.P.DataOffset = 0;
				root.PumpDeferred();
				Assert.AreEqual("3", GetText(p.A));
				
				p.D.ExcludeExtend = false;
				root.PumpDeferred();
				Assert.AreEqual("3", GetText(p.A));
				
				p.P.DataOffset = 1;
				root.PumpDeferred();
				Assert.AreEqual("3", GetText(p.A));
				
				p.D.SkipEnds = int2(0);
				root.PumpDeferred();
				Assert.AreEqual("0,3", GetText(p.A));
				
				p.P.DataOffset = 0;
				root.PumpDeferred();
				Assert.AreEqual("0,3", GetText(p.A));
			}
		}
		
		[Test]
		//somehow a 1-count was causing ExcludeExtend not to work
		public void One()
		{
			var p = new UX.PlotAxis.One();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual("two", GetText(p.XL));
				
				p.P.DataOffset = 0;
				root.StepFrame();
				Assert.AreEqual("one", GetText(p.XL));
			}
		}
	}
}