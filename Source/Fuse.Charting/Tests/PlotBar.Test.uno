using Uno;
using Uno.Collections;
using Uno.Compiler;
using Uno.Testing;
using Uno.UX;

using Fuse.Charting;
using Fuse.Controls;
using Fuse.Elements;

using FuseTest;

namespace Fuse.Charting.Test
{
	//this of course tests way more than just PlotBar, but the calculation involves so many details
	//it's hard to separate out testable bits
	public class PlotBarTest: TestBase
	{
		[Test]
		public void PlacementHorz()
		{
			var p = new UX.PlotBar.Placement();
			using (var root = TestRootPanel.CreateWithChild(p,int2(300,1000)))
			{
				root.StepFrameJS();
				
				var bars = Util.Children<PlotBar>(p.A);
				Assert.AreEqual(3,bars.Length);
				Compare(0,750, 100, 250, bars[0]);
				Compare(100,500,100,500, bars[1]);
				Compare(200,250,100,750, bars[2]);
				for (int i=0; i< 3; ++i)
				{
					//UNO: https://github.com/fusetools/uno/issues/1055
					var a = bars[i].Anchor.Y;
					Assert.AreEqual(100, a.Value);
					Assert.AreEqual(Unit.Percent, a.Unit);
					a = bars[i].Anchor.X;
					Assert.AreEqual(50,a.Value);
					Assert.AreEqual(Unit.Percent, a.Unit);
				}
				
				bars = Util.Children<PlotBar>(p.B);
				Assert.AreEqual(3,bars.Length);
				Compare(0,0, 100, 250, bars[0]);
				Compare(100,0,100,500, bars[1]);
				Compare(200,0,100,750, bars[2]);
				for (int i=0; i< 3; ++i)
				{
					var a = bars[i].Anchor.Y;
					Assert.AreEqual(0, a.Value);
					Assert.AreEqual(Unit.Percent, a.Unit);
				}
				
				bars = Util.Children<PlotBar>(p.C);
				Assert.AreEqual(3,bars.Length);
				Compare(0,400, 100, 100, bars[0]);
				Compare(100,200,100,200, bars[1]);
				Compare(200,400,100,300, bars[2]);
				var an = bars[0].Anchor.Y;
				Assert.AreEqual(0,an.Value);
				an = bars[1].Anchor.Y;
				Assert.AreEqual(100,an.Value);
				
				bars = Util.Children<PlotBar>(p.D);
				Assert.AreEqual(3,bars.Length);
				Compare(0,100,100,200,bars[0]);
				Compare(100,600,100,200,bars[1]);
				Compare(200,300,100,300,bars[2]);
				an = bars[0].Anchor.Y;
				Assert.AreEqual(100,an.Value);
				an = bars[1].Anchor.Y;
				Assert.AreEqual(100,an.Value);
				an = bars[2].Anchor.Y;
				Assert.AreEqual(0,an.Value);
				
				bars = Util.Children<PlotBar>(p.E);
				Compare(0,0, 100, 1000, bars[0]);
				Compare(100,0, 100, 1000, bars[1]);
				Compare(200,0, 100, 1000, bars[2]);
			}
		}
		
		[Test]
		public void PlacementVert()
		{
			var p = new UX.PlotBar.PlacementVert();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000,300)))
			{
				root.StepFrameJS();
				
				var bars = Util.Children<PlotBar>(p.A);
				Assert.AreEqual(3,bars.Length);
				Compare(0,200, 250, 100, bars[0]);
				Compare(0,100,500,100, bars[1]);
				Compare(0,0,750,100, bars[2]);
				for (int i=0; i< 3; ++i)
				{
					var a = bars[i].Anchor.X;
					Assert.AreEqual(0, a.Value);
					Assert.AreEqual(Unit.Percent, a.Unit);
					a = bars[i].Anchor.Y;
					Assert.AreEqual(50, a.Value);
					Assert.AreEqual(Unit.Percent, a.Unit);
				}
				
				bars = Util.Children<PlotBar>(p.B);
				Assert.AreEqual(3,bars.Length);
				Compare(750,200, 250,100, bars[0]);
				Compare(500,100,500,100, bars[1]);
				Compare(250,0,750,100, bars[2]);
				for (int i=0; i< 3; ++i)
				{
					var a = bars[i].Anchor.X;
					Assert.AreEqual(100, a.Value);
					Assert.AreEqual(Unit.Percent, a.Unit);
				}
				
				bars = Util.Children<PlotBar>(p.C);
				Assert.AreEqual(3,bars.Length);
				Compare(500,200, 100,100, bars[0]);
				Compare(600,100, 200,100, bars[1]);
				Compare(300,0, 300,100, bars[2]);
				var an = bars[0].Anchor.X;
				Assert.AreEqual(100,an.Value);
				an = bars[1].Anchor.X;
				Assert.AreEqual(0,an.Value);
				
				bars = Util.Children<PlotBar>(p.D);
				Assert.AreEqual(3,bars.Length);
				Compare(700,200, 200,100, bars[0]);
				Compare(200,100, 200, 100, bars[1]);
				Compare(400,0, 300,100, bars[2]);
				an = bars[0].Anchor.X;
				Assert.AreEqual(0,an.Value);
				an = bars[1].Anchor.X;
				Assert.AreEqual(0,an.Value);
				an = bars[2].Anchor.X;
				Assert.AreEqual(100,an.Value);
				
				bars = Util.Children<PlotBar>(p.E);
				Compare(0,200, 1000, 100, bars[0]);
				Compare(0,100, 1000, 100, bars[1]);
				Compare(0,0, 1000, 100, bars[2]);
			}
		}
		
		void Compare( float x, float y, float width, float height, Element e,
			[CallerFilePath] string filePath = "",
			[CallerLineNumber] int lineNumber = 0,
			[CallerMemberName] string memberName = "")
		{
			Assert.AreEqual( float2(x,y), e.ActualPosition, Assert.ZeroTolerance, filePath, lineNumber, 
				memberName + "-Position");
			Assert.AreEqual( float2(width,height), e.ActualSize, Assert.ZeroTolerance, filePath, lineNumber,
				memberName + "-Size");
		}
	}
}
