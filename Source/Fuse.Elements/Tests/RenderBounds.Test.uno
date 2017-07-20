using Fuse;
using Fuse.Elements;
using Fuse.Controls;

using FuseTest;

using Uno;
using Uno.Testing;

namespace Fuse.Test
{
	public class RenderBoundsTest : TestBase
	{
		[Test]
		public void Basics()
		{
			var tn = new UX.RenderBoundsBasicsTest();
			using (var root = TestRootPanel.CreateWithChild(tn,int2(1000)))
			{
				Assert.AreEqual( new Rect(20,30,540,540), tn.RenderBoundsWithoutEffects.FlatRect );
				Assert.AreEqual( new Rect(0,0,100,70), tn.P1.RenderBoundsWithoutEffects.FlatRect );
				Assert.AreEqual( new Rect(0,0,50,80), tn.P2.RenderBoundsWithoutEffects.FlatRect );
				Assert.AreEqual( float3(-15,0,0), tn.P4.RenderBoundsWithoutEffects.AxisMin);
				Assert.AreEqual( float3(65,80,0), tn.P4.RenderBoundsWithoutEffects.AxisMax );
				Assert.AreEqual( new Rect(-10,-10,10,27), tn.P3.RenderBoundsWithoutEffects.FlatRect );
				Assert.IsTrue( tn.P5.RenderBoundsWithoutEffects.IsEmpty );
			}
		}
		
		[Test]
		public void Stack()
		{
			var tn = new UX.RenderBoundsStackTest();
			using (var root = TestRootPanel.CreateWithChild(tn,int2(100)))
			{
				//force cached version to be generate before adding children
				Assert.AreEqual( new Rect(0,0,50,20), tn.P1.RenderBoundsWithoutEffects.FlatRect );
				Assert.AreEqual( new Rect(0,0,50,50), tn.P2.RenderBoundsWithoutEffects.FlatRect );

				for( int i=0; i < 3; ++i )
				{
					var p = new Panel();
					p.Height = 20;
					p.Color = float4(1);
					tn.P1.Children.Add(p);
				}
				root.UpdateLayout();

				Assert.AreEqual( new Rect(0,0,50,80), tn.P1.RenderBoundsWithoutEffects.FlatRect );
				Assert.AreEqual( new Rect(0,0,50,80), tn.P2.RenderBoundsWithoutEffects.FlatRect );
			}
		}
		
		[Test]
		public void Props()
		{
			var tn = new UX.RenderBoundsPropsTest();
			using (var root = TestRootPanel.CreateWithChild(tn,int2(1000)))
			{
				Assert.AreEqual( new Rect(0,0,100,100), tn.P1.RenderBoundsWithoutEffects.FlatRect );
				Assert.AreEqual( new Rect(0,0,100,100), tn.P2.RenderBoundsWithoutEffects.FlatRect );

				tn.P2.Offset = float2(1,0);
				root.UpdateLayout();

				Assert.AreEqual( new Rect(0,0,101,100), tn.P1.RenderBoundsWithoutEffects.FlatRect );
				Assert.AreEqual( new Rect(0,0,100,100), tn.P2.RenderBoundsWithoutEffects.FlatRect );
			}
		}
		
		[Test]
		public void Clip()
		{
			var tn = new UX.RenderBoundsClipTest();
			using (var root = TestRootPanel.CreateWithChild(tn,int2(1000)))
			{
				Assert.AreEqual( new Rect(0,0,100,100), tn.P1.RenderBoundsWithoutEffects.FlatRect );
				Assert.AreEqual( new Rect(-5,-5,105,105), tn.P2.RenderBoundsWithoutEffects.FlatRect );

				Assert.AreEqual( new Rect(15,5,100,100), tn.P3.RenderBoundsWithoutEffects.FlatRect );
				Assert.AreEqual( new Rect(15,5,105,105), tn.P4.RenderBoundsWithoutEffects.FlatRect );

				Assert.AreEqual( new Rect(50,50,300,200), tn.LocalRenderBounds.FlatRect );
			}
		}
		
		[Test]
		public void Containers()
		{
			var p = new UX.RenderBoundsContainer();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000)))
			{
				Assert.IsTrue(p.R1.LocalRenderBounds.IsEmpty);
				Assert.AreEqual( new Rect(0,0,125,200), p.R2.LocalRenderBounds.FlatRect );
				//High variance now since we have inprecise stroke estimations
				Assert.AreEqual( float2(-15,-15), p.R3.LocalRenderBounds.FlatRect.Minimum, 1.0f );
				Assert.AreEqual( float2(215,115), p.R3.LocalRenderBounds.FlatRect.Maximum, 1.0f );

				Assert.AreEqual( new Rect(60,50,110,130), p.C1.LocalRenderBounds.FlatRect );

				Assert.AreEqual( new Rect(0,0,200,100), p.I1.LocalRenderBounds.FlatRect );
				Assert.AreEqual( new Rect(0,50,200,150), p.I2.LocalRenderBounds.FlatRect );
				Assert.AreEqual( new Rect(0,50,200,150), p.P1.LocalRenderBounds.FlatRect );
				Assert.AreEqual( new Rect(0,0,225,130), p.I3.LocalRenderBounds.FlatRect );
			}
		}
		
		[Test]
		public void ChangeBackground()
		{
			var p = new UX.ChangeBackground();
			using (var root = TestRootPanel.CreateWithChild(p,int2(500)))
			{
				Assert.IsTrue(p.P1.LocalRenderBounds.IsEmpty);
				p.P1.Color = float4(1);
				Assert.AreEqual( new Rect(0,0,100,200), p.P1.LocalRenderBounds.FlatRect);
			}
		}
	}
}
