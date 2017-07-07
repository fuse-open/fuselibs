using Uno;
using Uno.Testing;

using FuseTest;
using Fuse.Controls;
using Fuse.Resources;

namespace Fuse.Controls.Panels.Test
{
	public class WrapPanelTest : TestBase
	{
		[Test]
		public void Issue2680()
		{
			var p = new UX.Issue2680();
			var root = TestRootPanel.CreateWithChild(p);
			
			Assert.AreEqual(float2(300,40), p.G.ActualSize);
		}
		
		[Test]
		public void Max()
		{
			var p = new UX.WrapPanel.Max();
			using (var root = TestRootPanel.CreateWithChild(p,int2(200)))
			{
				Assert.AreEqual(float4(10,10,80,100), ActualPositionSize(p.F));
				Assert.AreEqual(float2(100,120), p.W.ActualSize);
				Assert.AreEqual(float2(100,120), p.B.ActualSize);
				Assert.AreEqual(float2(80,100), p.O.ActualSize);
				
				Assert.AreEqual(float4(10,10,80,100), ActualPositionSize(p.F2));
				Assert.AreEqual(float2(100,120), p.W2.ActualSize);
				Assert.AreEqual(float2(100,120), p.B2.ActualSize);
				Assert.AreEqual(float2(80,100), p.O2.ActualSize);
			}
		}
		
		[Test]
		public void VerticalRightToLeft()
		{
			var p = new UX.WrapPanel.VerticalRightToLeft();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000)))
			{
				var right = 1000 - p.W.Padding.Z;
				var top = p.W.Padding.Y;
				Assert.AreEqual( float4(right-50, top, 50, 50), ActualPositionSize(p.P1));
				Assert.AreEqual( float4(right-60, top+50, 60, 40), ActualPositionSize(p.P2));
				Assert.AreEqual( float4(right-70, top, 10, 40), ActualPositionSize(p.P3));
				Assert.AreEqual( float4(right-100, top+10, 20, 50), ActualPositionSize(p.P4));
			}
		}
		
		[Test]
		public void Center()
		{
			var p = new UX.WrapPanel.Center();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000)))
			{
				Assert.AreEqual( float4(2,2,30*4,90), ActualPositionSize(p.W) );
			}
		}
		
		[Test]
		public void ChildSize()
		{
			var p = new UX.WrapPanel.ChildSize();
			using (var root = TestRootPanel.CreateWithChild(p,int2(700,100))) //height shouldn't matter
			{
				Assert.AreEqual( float4(5,5,190,20), ActualPositionSize(p.P1));
				Assert.AreEqual( float4(205,5,190,20), ActualPositionSize(p.P2));
				Assert.AreEqual( float4(405,5,190,20), ActualPositionSize(p.P3));
				Assert.AreEqual( float4(5,35,190,20), ActualPositionSize(p.P4));
			}
		}
		
		[Test]
		public void ItemSize()
		{
			var p = new UX.WrapPanel.ItemSize();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000)))
			{
				Assert.AreEqual( float4(0,0,20,50), ActualPositionSize(p.A1));
				Assert.AreEqual( float4(20,0,2,50), ActualPositionSize(p.A2));
				Assert.AreEqual( float4(0,0,10,100), ActualPositionSize(p.A3));
				Assert.AreEqual( float4(10,0,10,10), ActualPositionSize(p.A4));
			}
		}
		
		[Test]
		public void ContentAlignment()
		{
			var p = new UX.WrapPanel.ContentAlignment();
			using (var root = TestRootPanel.CreateWithChild(p,int2(200,1000)))
			{
				Assert.AreEqual( float4(0,4,100,2), ActualPositionSize(p.P1));
				Assert.AreEqual( float4(100,0,100,10), ActualPositionSize(p.P2));
				Assert.AreEqual( float4(0,10,100,30), ActualPositionSize(p.P3));
				Assert.AreEqual( float4(100,15,100,20), ActualPositionSize(p.P4));

				Assert.AreEqual( float4(0,0,2,100), ActualPositionSize(p.VT1));
				Assert.AreEqual( float4(0,100,10,100), ActualPositionSize(p.VT2));
				Assert.AreEqual( float4(10,0,30,100), ActualPositionSize(p.VT3));
				Assert.AreEqual( float4(10,100,20,100), ActualPositionSize(p.VT4));

				Assert.AreEqual( float4(4,0,2,100), ActualPositionSize(p.VC1));
				Assert.AreEqual( float4(0,100,10,100), ActualPositionSize(p.VC2));
				Assert.AreEqual( float4(10,0,30,100), ActualPositionSize(p.VC3));
				Assert.AreEqual( float4(15,100,20,100), ActualPositionSize(p.VC4));

				Assert.AreEqual( float4(8,0,2,100), ActualPositionSize(p.VB1));
				Assert.AreEqual( float4(0,100,10,100), ActualPositionSize(p.VB2));
				Assert.AreEqual( float4(10,0,30,100), ActualPositionSize(p.VB3));
				Assert.AreEqual( float4(20,100,20,100), ActualPositionSize(p.VB4));

				// Old RowAlignment tests
				Assert.AreEqual( float4(0,4,100,2), ActualPositionSize(p.RP1));
				Assert.AreEqual( float4(100,0,100,10), ActualPositionSize(p.RP2));
				Assert.AreEqual( float4(0,10,100,30), ActualPositionSize(p.RP3));
				Assert.AreEqual( float4(100,15,100,20), ActualPositionSize(p.RP4));
				
				Assert.AreEqual( float4(8,0,2,100), ActualPositionSize(p.RR1));
				Assert.AreEqual( float4(0,100,10,100), ActualPositionSize(p.RR2));
				Assert.AreEqual( float4(10,0,30,100), ActualPositionSize(p.RR3));
				Assert.AreEqual( float4(20,100,20,100), ActualPositionSize(p.RR4));
			}
		}

	}
}
