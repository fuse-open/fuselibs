using Uno;
using Uno.Collections;
using Uno.Testing;
using Fuse;
using Fuse.Controls;
using Fuse.Elements;
using FuseTest;

namespace Fuse.Test
{

	public class SizingContainerTest : TestBase
	{
		[Test]
		public void CalcScaleStretch()
		{
			var sc = new Internal.SizingContainer();
			sc.padding = float4(0);
			sc.SetStretchMode( StretchMode.PointPrecise );
			Assert.AreEqual( float2(1,1), sc.CalcScale( float2(123,456), float2(23, 45) ) );
			
			sc.SetStretchMode( StretchMode.Fill );
			Assert.AreEqual( float2(2,3), sc.CalcScale( float2(200,150), float2(100,50) ) );
			Assert.AreEqual( float2(0.5f,0.25f), sc.CalcScale( float2(150,100), float2(300,400) ) );
			
			sc.SetStretchMode( StretchMode.Scale9 );
			Assert.AreEqual( float2(2,3), sc.CalcScale( float2(200,150), float2(100,50) ) );
			Assert.AreEqual( float2(0.5f,0.25f), sc.CalcScale( float2(150,100), float2(300,400) ) );
			
			sc.SetStretchMode( StretchMode.Uniform );
			Assert.AreEqual( float2(2,2), sc.CalcScale( float2(200,500), float2(100,100) ) );
			Assert.AreEqual( float2(2,2), sc.CalcScale( float2(500,200), float2(100,100) ) );
			
			sc.SetStretchMode( StretchMode.UniformToFill );
			Assert.AreEqual( float2(5,5), sc.CalcScale( float2(200,500), float2(100,100) ) );
			Assert.AreEqual( float2(5,5), sc.CalcScale( float2(500,200), float2(100,100) ) );
			
			sc.SetStretchMode( StretchMode.Fill );
			sc.padding = float4(10,20,30,40);
			Assert.AreEqual( float2(2,3), sc.CalcScale( float2(240,210), float2(100,50) ) );
		}
		
		[Test]
		public void CalcScaleStretchSnap()
		{
			var sc = new Internal.SizingContainer();
			sc.padding = float4(0);
			sc.absoluteZoom = 0.5f;
			sc.snapToPixels = true;
			sc.SetStretchMode( StretchMode.Fill );
			Assert.AreEqual( float2(2.02f,3), sc.CalcScale( float2(201,149), float2(100,50) ) );
			Assert.AreEqual( float2(0.52666f,0.255f), sc.CalcScale( float2(159,101), float2(300,400) ) );
			
		}
		
		[Test]
		public void CalcContentSize()
		{
			var sc = new Internal.SizingContainer();
			sc.SetStretchMode( StretchMode.PixelPrecise );
			sc.absoluteZoom = 0.5f;
			Assert.AreEqual( float2(100,50), sc.CalcContentSize( float2(80,40), int2(50,25) ) );
			
			sc.snapToPixels = true;
			sc.SetStretchMode( StretchMode.Fill );
			Assert.AreEqual( float2(82,70), sc.CalcContentSize( float2(81.2f,70.2f), int2(0) ) );
		}
	
		[Test]
		public void CalcStretchDirection()
		{
			var sc = new Internal.SizingContainer();
			sc.padding = float4(0);
			sc.SetStretchMode( StretchMode.Uniform );
			sc.SetStretchDirection( StretchDirection.DownOnly );
			Assert.AreEqual( float2(1,1), sc.CalcScale( float2(200,500), float2(100,100) ) );
			Assert.AreEqual( float2(0.5f,0.5f), sc.CalcScale( float2(200,500), float2(400,1000) ) );
			
			sc.SetStretchDirection( StretchDirection.UpOnly );
			Assert.AreEqual( float2(2,2), sc.CalcScale( float2(200,500), float2(100,100) ) );
			Assert.AreEqual( float2(1,1), sc.CalcScale( float2(200,500), float2(400,1000) ) );
		}
		
		[Test]
		public void CalcOrigin()
		{
			var sc = new Internal.SizingContainer();
			sc.padding = float4(0);
			sc.align = Alignment.Center;
			Assert.AreEqual( float2(30,70), sc.CalcOrigin( float2(100,200), float2(40,60) ) );
			
			sc.padding = float4(1,5,10,20);
			sc.align = Alignment.TopLeft;
			Assert.AreEqual( float2(1,5), sc.CalcOrigin( float2(100,200), float2(40,60) ) );
			
			sc.align = Alignment.BottomRight;
			Assert.AreEqual( float2(100-40-10,200-60-20), sc.CalcOrigin( float2(100,200), float2(40,60) ) );
		}
		
		[Test]
		public void CalcOriginSnap()
		{
			var sc = new Internal.SizingContainer();
			sc.padding = float4(0);
			sc.align = Alignment.Center;
			sc.snapToPixels = true;
			sc.absoluteZoom = 0.5f;
			Assert.AreEqual( float2(30,70), sc.CalcOrigin( float2(99,201), float2(40,60) ) );
		}
		
		[Test]
		public void CalcClip()
		{
			var sc = new Internal.SizingContainer();
			sc.padding = float4(0);
			var o = float2(-50,25);
			var s = float2(200,50);
			Assert.AreEqual( float4(0.25f,0,0.75f,1), sc.CalcClip( float2(100, 100), ref o, ref s ) );
			Assert.AreEqual( float2(0,25), o );
			Assert.AreEqual( float2(100,50), s );
			
			o = float2(50,50);
			s = float2(30,100);
			Assert.AreEqual( float4(0,0,1,0.5f), sc.CalcClip( float2(100, 100), ref o, ref s ) );
			Assert.AreEqual( float2(50,50), o );
			Assert.AreEqual( float2(30,50), s );
			
			sc.padding = float4(10,20,30,40);
			o = float2(0,0);
			s = float2(100,100);
			Assert.AreEqual( float4(0.1f,0.2f,0.7f,0.6f), sc.CalcClip( float2(100,100), ref o, ref s ) );
			Assert.AreEqual( float2(10,20), o );
			Assert.AreEqual( float2(60,40), s );
		}
		
		[Test]
		//Uniform is properly defined when a desired dimension is zero
		public void CalcZeroUniform()
		{
			var sc = new Internal.SizingContainer();
			sc.SetStretchMode( StretchMode.Uniform );
			Assert.AreEqual( float2(10,10), sc.CalcScale( float2(100,10), float2(10, 0) ) );
			Assert.AreEqual( float2(5,5), sc.CalcScale( float2(20,50), float2(0, 10) ) );
		}
	}

}
