using Uno;
using Uno.Testing;
using Fuse;
using FuseTest;

namespace Fuse.Test
{
	public class VisualBoundsTest : TestBase
	{
		[Test]
		public void Empty()
		{
			var nb = VisualBounds.Empty;
			Assert.IsTrue(nb.IsEmpty);
			Assert.IsFalse(nb.IsInfinite);
			
			nb = nb.AddPoint(float3(0));
			Assert.IsFalse(nb.IsEmpty);
		}
		
		[Test]
		public void Infinite()
		{
			Assert.IsTrue( VisualBounds.Infinite.IsInfinite );
			Assert.IsFalse( VisualBounds.Infinite.IsEmpty );
		}
		
		[Test]
		public void ContainsPoint()
		{
			var nb = VisualBounds.Empty;
			Assert.IsFalse( nb.ContainsPoint(float2(10,20)) );
			
			nb = nb.AddRect( float2(0,5), float2(40,30) );
			Assert.IsTrue( nb.ContainsPoint(float2(10,20)) );
			Assert.IsFalse( nb.ContainsPoint(float2(-1,20)) );
			Assert.IsFalse( nb.ContainsPoint(float2(10,40)) );
		}

		[Test]
		public void ContainsRay()
		{
			var nb = VisualBounds.Rect( float3(10), float3(100) );
			
			Assert.IsTrue( nb.IntersectsRay( new Ray(float3(10,10,0), float3(0,0,1)) ) );
			Assert.IsFalse( nb.IntersectsRay( new Ray(float3(0,10,0), float3(0,0,1)) ) );
		}
		
		[Test]
		public void Transform()
		{
			var b = VisualBounds.Rect( float2(-10), float2(10) );
			
			var fm = FastMatrix.Identity();
			fm.AppendRotationQuaternion( Quaternion.RotationY(Math.PIf/2) );
			var a = VisualBounds.Empty.Merge(b, fm);
			Assert.AreEqual( float3(0,-10,-10), a.AxisMin );
			Assert.AreEqual( float3(0,10,10), a.AxisMax );
		}
		
		[Test]
		public void Scale()
		{
			var b = VisualBounds.Rect( float3(-10), float3(100) );
			var c = b.Scale( float3(0.5f,1,2) );
			Assert.AreEqual( float3(-5,-10,-20), c.AxisMin);
			Assert.AreEqual( float3(50,100,200), c.AxisMax);
		}
	}
}
