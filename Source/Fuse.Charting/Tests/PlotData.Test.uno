using Uno;
using Uno.Collections;
using Uno.Testing;
using Uno.UX;

using Fuse.Charting;
using Fuse.Controls;
using Fuse.Elements;

using FuseTest;

namespace Fuse.Test
{
	public class PlotDataTest: TestBase
	{
		float4 Place(Node v)
		{
			var e = v as Element;
			if (e == null)
				return float4(0);
			return float4( e.ActualPosition, e.ActualSize );
		}
		
		[Test]
		extern(!MSVC)
		public void Basic()
		{
			var p = new UX.PlotData.Basic();
			using (var root = TestRootPanel.CreateWithChild(p,int2(500,1000)))
			{
				root.StepFrameJS();

				//There's no actual guarantee on the ordering, but we have no other easy way to check this,
				//so we'll assume index ordering for now
				int b = IndexOf(p.B.Children,p.B.FirstChild<PlotBar>());
				Assert.IsTrue( b + 4 < p.B.Children.Count );
				Assert.AreEqual( float4(0,800,100,200), Place(p.B.Children[b+0]));
				Assert.AreEqual( float4(100,600,100,400), Place(p.B.Children[b+1]));
				Assert.AreEqual( float4(400,0,100,1000), Place(p.B.Children[b+4]));
				
				//check expecting anchoring
				var e = p.B.Children[b] as Element;
				Assert.AreEqual( new Size2( new Size(50,Unit.Percent), new Size(100, Unit.Percent)), e.Anchor );
				Assert.AreEqual( new Size( 10, Unit.Percent ), e.X );
				Assert.AreEqual( new Size( 100, Unit.Percent ), e.Y );
				
				b = IndexOf(p.C.Children,p.C.FirstChild<CurvePoint>());
				Assert.AreEqual( float2(0.1f,0.8f), (p.C.Children[b+0] as CurvePoint).At);
				Assert.AreEqual( float2(0.5f,0.4f), (p.C.Children[b+2] as CurvePoint).At);
				Assert.AreEqual( float2(0.9f,0f), (p.C.Children[b+4] as CurvePoint).At);
			}
		}
		
		[Test]
		public void Series()
		{
			var p = new UX.PlotData.Series();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual( "1,2,3,4,5", GetText(p.B));
				Assert.AreEqual( "9,8,7,6,5", GetText(p.C));
			}
		}
		
		[Test]
		public void Filter()
		{
			var p = new UX.PlotData.Filter();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual("2,3,4,5,6,7,8,9", GetText(p.A));
				
				p.D.ExcludeExtend = true;
				root.PumpDeferred();
				Assert.AreEqual("3,4,5,6,7", GetText(p.A));
				
				p.D.SkipEnds = int2(2,1);
				root.PumpDeferred();
				Assert.AreEqual("5,6", GetText(p.A));
				
				p.P.DataOffset = 0;
				root.PumpDeferred();
				Assert.AreEqual("2,3", GetText(p.A));
				
				p.D.ExcludeExtend = false;
				root.PumpDeferred();
				Assert.AreEqual("2,3,4,5", GetText(p.A));
				
				p.P.DataOffset = 1;
				root.PumpDeferred();
				Assert.AreEqual("2,3,4,5,6", GetText(p.A));
				
				p.D.SkipEnds = int2(0);
				root.PumpDeferred();
				Assert.AreEqual("0,1,2,3,4,5,6,7", GetText(p.A));
				
				p.P.DataOffset = 0;
				root.PumpDeferred();
				Assert.AreEqual("0,1,2,3,4,5,6", GetText(p.A));
				
				p.P.DataLimit = 1;
				root.PumpDeferred();
				Assert.AreEqual("0,1,2", GetText(p.A));
				
				p.D.ExcludeExtend = true;
				root.PumpDeferred();
				Assert.AreEqual("0", GetText(p.A));
			}
		}
		
		//missing functionality in our IList
		int IndexOf( IList<Node> list, Node obj )
		{
			for (int i=0; i < list.Count; ++i)
				if (list[i] == obj)
					return i;
			return -1;
		}
	}
}