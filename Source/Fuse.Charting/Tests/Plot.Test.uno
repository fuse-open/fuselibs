using Uno;
using Uno.Collections;
using Uno.Testing;
using Uno.UX;

using Fuse.Charting;
using Fuse.Controls;
using Fuse.Elements;

using FuseTest;

namespace Fuse.Charting.Test
{
	public class PlotTest: TestBase
	{
		[Test]
		public void Step()
		{
			var p = new UX.Plot.Step();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();

				//like in PlotData, there's no guarantee of ordering, but it's easier to test assuming there is
				int b = Util.IndexOf(p.B.Children,p.B.FirstChild<Text>());
				Assert.AreEqual( "0", (p.B.Children[b+0] as Text).Value);
				Assert.AreEqual( "25", (p.B.Children[b+25] as Text).Value);
				Assert.AreEqual( 50, Util.CountChildren<Text>(p.B) );
				Assert.AreEqual( 0, p.plot.DataOffset );
				
				p.CallNext.Perform();
				root.StepFrameJS();
				b = Util.IndexOf(p.B.Children,p.B.FirstChild<Text>());
				Assert.AreEqual( "50", (p.B.Children[b+0] as Text).Value);
				Assert.AreEqual( "75", (p.B.Children[b+25] as Text).Value);
				Assert.AreEqual( 50, Util.CountChildren<Text>(p.B) );
				Assert.AreEqual( 50, p.plot.DataOffset );
				
				p.CallNext.Perform(); //-> 100
				p.CallNext.Perform(); //-> 150
				p.CallNext.Perform(); //too far, stops and keeps limit in range
				root.StepFrameJS();
				Assert.AreEqual( "150", (p.B.Children[b+0] as Text).Value);
				Assert.AreEqual( "175", (p.B.Children[b+25] as Text).Value);
				Assert.AreEqual( "199", (p.B.Children[b+49] as Text).Value);
				Assert.AreEqual( 50, Util.CountChildren<Text>(p.B) );
				Assert.AreEqual( 150, p.plot.DataOffset );
			}
			
		}
		
		[Test]
		public void PreserveObject()
		{
			var p = new UX.Plot.PreserveObject();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				
				for (int charm=0; charm < 3; ++charm)
				{
					var b1 = Util.Children<Text>(p.B);
					var c1 = Util.Children<Text>(p.C);
					Assert.AreEqual(10, b1.Length);
					
					p.plot.DataOffset = 6;
					root.StepFrame();
					
					var b2 = Util.Children<Text>(p.B);
					var c2 = Util.Children<Text>(p.C);
					for (int i=1; i < 10; ++i)
					{
						Assert.AreEqual( b1[i], b2[i-1] );
						Assert.AreEqual( c1[i], c2[i-1] );
					}
					
					p.plot.DataOffset = 3;
					root.StepFrame();
					var b3 = Util.Children<Text>(p.B);
					var c3 = Util.Children<Text>(p.C);
					for (int i=0; i < 7; ++i)
					{
						Assert.AreEqual( b2[i], b3[i+3] );
						Assert.AreEqual( c2[i], c3[i+3] );
					}
					
					p.plot.DataOffset = 5;
					root.StepFrame();
				}
			}
		}
		
		[Test]
		public void DataLimit()
		{
			var p = new UX.Plot.DataLimit();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();

				for (int charm=0; charm < 3; ++charm)
				{
					Assert.AreEqual("0,1,2,3,4,5,6,7", Util.GetText(p.B));
					
					p.plot.DataLimit = 7;
					root.StepFrame();
					Assert.AreEqual("0,1,2,3,4,5,6", Util.GetText(p.B));
					
					p.plot.DataLimit = 4;
					root.StepFrame();
					Assert.AreEqual("0,1,2,3", Util.GetText(p.B));
					
					p.plot.DataLimit = 8;
					root.StepFrame();
				}
			}
		}
		
		[Test]
		//test weigths and object access
		public void CumulativeObject()
		{
			var p = new UX.Plot.CumulativeObject();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				
				var rc = Util.Children<RangeControl>(p.B);
				Assert.AreEqual(4,rc.Length);
				//spot checks
				Assert.AreEqual(0.1f, rc[0].Maximum);
				Assert.AreEqual(0.6f, rc[2].Maximum);
				Assert.AreEqual(float4(0,1,0,1), rc[1].Color);
				Assert.AreEqual(0.1f, rc[0].Value);
				Assert.AreEqual(0.4f, rc[3].Value);
				
				Assert.AreEqual("un,deux,trois,quatre", Util.GetText(p.B));
			}
		}
		
		[Test]
		public void DataSpecRange()
		{
			var p = new UX.Plot.DataSpecRange();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				
				var pb = PlotBehavior.FindPlot(p.plot);
				var ds = pb.DataStats;
				var ps = pb.PlotStats;
				
				Assert.AreEqual(5, ps.FullCount);
				Assert.AreEqual(3, ps.Count);
				Assert.AreEqual( float4(0,5,4,4), ds.Minimum );
				Assert.AreEqual( float4(4,25,40,40), ds.Maximum );
				Assert.AreEqual( float4(10,64,29,119), ds.Total);
				
				Assert.AreEqual( float4(1,10,0,0), ps.Minimum );
				Assert.AreEqual( float4(3,20,40,40), ps.Maximum );
				Assert.AreEqual( 7, ps.Steps.Y );
				Assert.AreEqual( int2(1,4), ps.Range );
				Assert.AreEqual( 1, ps.Offset );
			}
		}
		
	}
}