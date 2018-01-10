using Uno;
using Uno.Testing;

using FuseTest;

namespace Fuse.Controls.Primitives.Test
{
	public class PathTest : TestBase
	{
		[Test]
		[extern(MSVC) Ignore("no surface backend")]
		//just some spot tests for sanity
		public void Segment()
		{
			var p = new UX.Path.Segment();
			using (var root = TestRootPanel.CreateWithChild(p,int2(100)))
			{
				Assert.AreEqual( float2(50,100), p.p5.Float2Value );
				Assert.AreEqual( Math.PIf, p.ta5.FloatValue );
				
				p.dist.Value = 0.75f;
				root.PumpDeferred();
				Assert.AreEqual( float2(0,50), p.p5.Float2Value );
				Assert.AreEqual( -Math.PIf/2, p.ta5.FloatValue );
				
				var tfb = root.CaptureDraw();
				tfb.AssertPixel( float4(0,0,0,1), int2(50,99) );
				tfb.AssertPixel( float4(1), int2(50,80) );
				tfb.AssertPixel( float4(0,0,0,1), int2(0,50) );
				tfb.AssertPixel( float4(1), int2(10,50) );
				tfb.AssertPixel( float4(1), int2(50,0) );
				tfb.Dispose();
				
				p.thePath.PathStart = -0.26f;
				p.thePath.PathEnd = 0.26f;
				tfb = root.CaptureDraw();
				tfb.AssertPixel( float4(1), int2(50,99) );
				tfb.AssertPixel( float4(1), int2(50,80) );
				tfb.AssertPixel( float4(0,0,0,1), int2(0,50) );
				tfb.AssertPixel( float4(1), int2(10,50) );
				tfb.AssertPixel( float4(0,0,0,1), int2(50,0) );
				tfb.Dispose();
			}
		}
		
		[Test]
		[extern(MSVC) Ignore("no surface backend")]
		public void MeasureMode()
		{	
			var p = new UX.Path.MeasureMode();
			using (var root = TestRootPanel.CreateWithChild(p,int2(400)))
			{
				Assert.AreEqual( float2(100,0), p.p5.Float2Value );
				Assert.AreEqual( 0, p.ta5.FloatValue );
				
				var tfb = root.CaptureDraw();
				tfb.AssertPixel( float4(0,0,0,1), int2(50,0) );
				tfb.AssertPixel( float4(0,0,0,1), int2(250,0) );
				tfb.AssertPixel( float4(1), int2(40,0) );
				tfb.AssertPixel( float4(1), int2(260,0) );
				tfb.Dispose();
			}
		}
		
	}
}
