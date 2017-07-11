using Uno;
using Uno.Compiler;
using Uno.Testing;

using Fuse;
using Fuse.Internal;
using FuseTest;

namespace Uno.Testing
{
	public static partial class Assert
	{
		public static void IsIdentity(float4x4 m, 
			[CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0, [CallerMemberName] string memberName = "")
		{
			Assert.AreEqual(float4(1,0,0,0),m[0], Assert.ZeroTolerance, filePath, lineNumber, memberName);
			Assert.AreEqual(float4(0,1,0,0),m[1], Assert.ZeroTolerance, filePath, lineNumber, memberName);
			Assert.AreEqual(float4(0,0,1,0),m[2], Assert.ZeroTolerance, filePath, lineNumber, memberName);
			Assert.AreEqual(float4(0,0,0,1),m[3], Assert.ZeroTolerance, filePath, lineNumber, memberName);
		}
		
		public static void EqualTransformCoordinate(float3 expect, float3 input, float4x4 m, 
			float eps = Assert.ZeroTolerance,
			[CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0, [CallerMemberName] string memberName = "")
		{
			var q = Vector.TransformCoordinate(input,m);
			Assert.AreEqual(expect,q, eps, filePath, lineNumber, memberName);
		}
		
		public static void EqualTransformCoordinateXY(float2 expect, float3 input, float4x4 m, 
			float eps = Assert.ZeroTolerance,
			[CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0, [CallerMemberName] string memberName = "")
		{
			var q = Vector.TransformCoordinate(input,m);
			Assert.AreEqual(expect,q.XY, eps, filePath, lineNumber, memberName);
		}
	}
}

namespace Fuse.Test
{
	public class FrustumMatrixTest : TestBase
	{
		static string d(float4x4 m)
		{
			return "[" + m[0] + "; " + m[1] + "; " + m[2] + "; " + m[3] + "]";
		}
		
		[Test]
		public void PerspectiveView()
		{
			var m = FrustumMatrix.PerspectiveView( float2(1000, 500), 200, float2(0.5f));
			Assert.AreEqual( float4(1,0,0,0),m[0] );
			Assert.AreEqual( float4(0,-1,0,0),m[1] );
			Assert.AreEqual( float4(0,0,1,0),m[2] );
			Assert.AreEqual( float4(-500,250,200,1),m[3] );
			
			var mi = FrustumMatrix.PerspectiveViewInverse( float2(1000, 500), 200, float2(0.5f));
			Assert.IsIdentity(Matrix.Mul(m,mi));
		}
		
		static void dtrans(float4x4 m, float3 p)
		{
			var q = Vector.TransformCoordinate(p,m);
			var r = Vector.Transform(float4(p,0),m);
			debug_log p + " => " + q + " / " + r;
		}
		
		[Test]
		public void Projection()
		{
			float4x4 p;
			Assert.IsTrue(FrustumMatrix.TryPerspectiveProjection( float2(1000, 500), 10, 1000, 200, out p ));
			float4x4 pi;
			Assert.IsTrue(FrustumMatrix.TryPerspectiveProjectionInverse( float2(1000, 500), 10, 1000, 200, out pi));
			Assert.IsIdentity(Matrix.Mul(p,pi));

			Assert.EqualTransformCoordinate(float3(0,0,1000),float3(0,0,1),pi, 0.01f);
			Assert.EqualTransformCoordinate(float3(0,0,10),float3(0,0,-1),pi, 0.01f);

			Assert.EqualTransformCoordinateXY(float2(0,0),float3(0,0,-200),p);
			Assert.EqualTransformCoordinateXY(float2(-1,-1),float3(500,250,-200),p);
			Assert.EqualTransformCoordinateXY(float2(1,1),float3(-500,-250,-200),p);
		}
		
		[Test]
		public void ProjectionView()
		{
			float4x4 p;
			Assert.IsTrue(FrustumMatrix.TryPerspectiveProjection( float2(1624,914), 10, 1000, 200, out p ));
			var v = FrustumMatrix.PerspectiveView( float2(1624,914), 200, float2(0.5f,0.5f) );
			var pv = Matrix.Mul(v,p);
			
			Assert.EqualTransformCoordinateXY(float2(0,0),float3(1624/2,914/2,0),pv);
			Assert.EqualTransformCoordinateXY(float2(-1,1),float3(0,0,0),pv);
			Assert.EqualTransformCoordinateXY(float2(1,-1),float3(1624,914,0),pv);
		}
		
	}
}
