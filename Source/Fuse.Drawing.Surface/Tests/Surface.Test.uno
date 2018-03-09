using Uno;
using Uno.Testing;

using Fuse.Drawing;

using FuseTest;

namespace Fuse.Test
{
	public class SurfaceTest : TestBase
	{
		[Test]
		public void EnumChecks()
		{
			//CoreGraphicsSurface (+perhaps others) use the specific in values of enums for simplicity
			Assert.AreEqual( 0, (int)LineCap.Butt );
			Assert.AreEqual( 1, (int)LineCap.Round );
			Assert.AreEqual( 2, (int)LineCap.Square );
			
			Assert.AreEqual( 0, (int)LineJoin.Miter );
			Assert.AreEqual( 1, (int)LineJoin.Round );
			Assert.AreEqual( 2, (int)LineJoin.Bevel );
			
			//TODO: If we supported GetNames on the enum we could ensure the count as well
		}
		
		[Test]
		public void DotNetAdjustedEndPoints()
		{
			//these tests have the bounds Y-inverted since I drew them on my graph paper that way. :/
			Assert.AreEqual( float4(4.0588f, 7.2352f, 8.6470f, -0.4117f), 
				DotNetUtil.AdjustedEndPoints( float4(2,1, 11, 6), float2(6,4), float2(9,-1) ), 1e-4f );
				
			Assert.AreEqual( float4(12.4137f, 4.9655f, 2.0689f, 0.8275f), 
				DotNetUtil.AdjustedEndPoints( float4(2,1, 12, 6), float2(10,4), float2(5,2) ), 1e-4f );
			
			Assert.AreEqual( float4(12.8648f, -0.8108f, 13.9189f, 5.5135f), 
				DotNetUtil.AdjustedEndPoints( float4(2,1, 11, 6), float2(13,0), float2(14,6) ), 1e-4f );
				
			Assert.AreEqual( float4(-5,0, 10,0),
				DotNetUtil.AdjustedEndPoints( float4(-5,-3, 10,-6), float2(0,0), float2(1,0)), 1e-4f );
				
			Assert.AreEqual( float4(1,2, 1,8),
				DotNetUtil.AdjustedEndPoints( float4(0,8, 5,2), float2(1,0), float2(1,10)), 1e-4f );
	
			//not these
			Assert.AreEqual( float4(0,0,200,200),
				DotNetUtil.AdjustedEndPoints( float4(0,0,200,200), float2(80,80), float2(300,300)), 1e-4f );
		}
		
		[Test]
		public void DotNetAdjustedOffsets()
		{
			float2 s = float2(0);
			float2 e = float2(5);
			Assert.AreEqual( float2(1f/2.5f,0.4f), 
				DotNetUtil.AdjustedOffsets( float2(2), float2(4), ref s, ref e ), 1e-4f );
				
			s = float2(1,0);
			e = float2(9,0);
			Assert.AreEqual( float2(1f/2f,0f), 
				DotNetUtil.AdjustedOffsets( float2(-1,0), float2(4,0), ref s, ref e ), 1e-4f );
				
			s = float2(4,7);
			e = float2(4,0);
			Assert.AreEqual( float2(6f/8f,0.25f), 
				DotNetUtil.AdjustedOffsets( float2(4,5), float2(4,-1), ref s, ref e ), 1e-4f );
				
			s = float2(100);
			e = float2(0);
			Assert.AreEqual( float2(1f/2,0.25f), 
				DotNetUtil.AdjustedOffsets( float2(75), float2(25), ref s, ref e ), 1e-4f );
		}
	}
	
}
