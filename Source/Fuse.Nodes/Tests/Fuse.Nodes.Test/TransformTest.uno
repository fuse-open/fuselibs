using Uno;
using Uno.Compiler;
using Uno.Testing;
using Uno.UX;

using Fuse;

using FuseTest;

namespace Fuse.Test
{
	public class TransformTest : TestBase
	{
		[Test]
		public void WorldInvalidate()
		{
			var tn = new UX.TransformTestNode();
			using (var root = TestRootPanel.CreateWithChild(tn))
			{
				Assert.AreEqual( 0, tn.PA.WorldTransform.M41 );
				Assert.AreEqual( 1, tn.PB.WorldTransform.M41 );
				Assert.AreEqual( 11, tn.PC.WorldTransform.M41 );

				tn.TRoot.X = 100;
				Assert.AreEqual( 100, tn.PA.WorldTransform.M41 );
				Assert.AreEqual( -101, tn.PB.WorldTransformInverse.M41 );
				Assert.AreEqual( 111, tn.PC.WorldTransform.M41 );

				//newly added
				var q = new Translation{X = 1000};
				tn.PB.Children.Add(q);
				Assert.AreEqual( 100, tn.PA.WorldTransform.M41 );
				Assert.AreEqual( -1111, tn.PC.WorldTransformInverse.M41 );
				Assert.AreEqual( 1101, tn.PB.WorldTransform.M41 );

				tn.PB.Children.Remove(q);
				Assert.AreEqual( 101, tn.PB.WorldTransform.M41 );
				Assert.AreEqual( 111, tn.PC.WorldTransform.M41 );

				//with intervening nodes
				tn.TRoot.X = 0;
				Assert.AreEqual( 0, tn.D4.WorldTransform.M41 );
				tn.D1.Children.Add(q);
				Assert.AreEqual( 1000, tn.D4.WorldTransform.M41 );
				Assert.AreEqual( 1, tn.D4.WorldTransform.M42 );
			}
		}
		
		static void CheckTransform(float3 expect, float3 input, Transform transform,
			[CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0, [CallerMemberName] string memberName = "")
		{
			var f = FastMatrix.Identity();
			transform.AppendTo(f);
			var q = Vector.TransformCoordinate(input, f.Matrix);
			Assert.AreEqual(expect, q, Assert.ZeroTolerance, filePath, lineNumber, memberName);
		}
		
		[Test]
		public void Rotation()
		{
			var r = new Rotation();
			r.DegreesZ = 90;
			CheckTransform(float3(1,1,0), float3(1,-1,0), r);
			Assert.IsTrue(r.IsFlat);
			
			r.DegreesZ = 0;
			r.DegreesY = 90;
			CheckTransform(float3(1,1,1), float3(-1,1,1), r);
			Assert.IsFalse(r.IsFlat);
			
			r.EulerAngleDegrees = float3(90,0,0);
			CheckTransform(float3(0,0,1), float3(0,1,0), r);
			Assert.IsFalse(r.IsFlat);
			
			r.EulerAngle = float3(Math.PIf/2,0,Math.PIf);
			CheckTransform(float3(0,0,-1), float3(0,1,0), r);
		}
		
		[Test]
		public void Scaling()
		{
			var s = new Scaling();
			s.Vector = float3(1,2,3);
			CheckTransform(float3(2,4,6), float3(2), s);
			Assert.IsTrue(s.IsFlat);
			
			s.Factor = 3;
			CheckTransform(float3(3,6,9), float3(1,2,3), s);
		}
		
		[Test]
		public void Translation()
		{
			var t = new Translation();
			t.X = -5;
			t.Y = 3;
			t.Z = 10;
			CheckTransform(float3(-4,4,11),float3(1), t);
			Assert.IsFalse(t.IsFlat);
			
			t.Vector = float3(1,-4,0);
			CheckTransform(float3(6,0,3), float3(5,4,3), t);
			Assert.IsTrue(t.IsFlat);
		}
		
		[Test] 
		public void TranslationRelative()
		{
			var p = new UX.TranslationRelative();
			using (var root = TestRootPanel.CreateWithChild(p, int2(100)))
			{
				Assert.AreEqual( 10 + 30*0.5f, p.P2.WorldTransform.M41 );
				Assert.AreEqual( 20 + 40*0.25f, p.P2.WorldTransform.M42 );

				Assert.AreEqual( 50 - 20*0.5f, p.P1.WorldTransform.M41 );
				Assert.AreEqual( 60 - 30*1f, p.P1.WorldTransform.M42 );

				//first time is easy since the transform is deferred you can't tell if the subscriptions are correct
				Assert.AreEqual( 30, p.P3.WorldTransform.M41 );
				Assert.AreEqual( 40, p.P3.WorldTransform.M42 );
				Assert.AreEqual( 30, p.P5.WorldTransform.M41 );
				Assert.AreEqual( 40, p.P5.WorldTransform.M42 );

				Assert.AreEqual( 30, p.P4.WorldTransform.M41 );
				Assert.AreEqual( 40, p.P4.WorldTransform.M42 );
				Assert.AreEqual( 30, p.P6.WorldTransform.M41 );
				Assert.AreEqual( 40, p.P6.WorldTransform.M42 );

				//so change the size and see that everything updates
				p.P2.Width = Size.Points(20);
				root.IncrementFrame();

				Assert.AreEqual( 20, p.P3.WorldTransform.M41 );
				Assert.AreEqual( 20, p.P5.WorldTransform.M41 );

				Assert.AreEqual( 20, p.P4.WorldTransform.M41 );
				Assert.AreEqual( 20, p.P6.WorldTransform.M41 ); //trouble point for issue 1881
			}
		}
	}
}
