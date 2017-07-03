using Uno;
using Uno.Testing;

using Fuse;
using FuseTest;

namespace Fuse.Test
{
	public class FastMatrixTest : TestBase
	{
		[Test]
		public void PrependTranslation1()
		{
			var f = FastMatrix.Identity();
			f.PrependTranslation(100,50,25);
			Assert.AreEqual(100,f.Matrix.M41);
		}

		[Test]
		public void PrependTranslation2()
		{
			var f = FastMatrix.FromFloat4x4(Matrix.Translation(float3(10,20,30)));
			f.PrependTranslation(30,20,10);
			Assert.AreEqual(Matrix.Translation(float3(40)), f.Matrix);
		}

		[Test]
		public void PrependTranslation3()
		{
			var s = Matrix.Scaling(2.0f);
			var r = Matrix.RotationX(Math.PIf / 2.0f);
			var t = Matrix.Translation(float3(10, 20, 30));
			var m = Matrix.Mul(s, r, t);
			var f = FastMatrix.FromFloat4x4(m);
			f.PrependTranslation(float3(30, 20, 10));
			Assert.AreEqual(Matrix.Mul(Matrix.Translation(30, 20, 10), m), f.Matrix);
		}

		[Test]
		public void AppendRotation1()
		{
			var f = FastMatrix.Identity();
			f.AppendRotation(Math.PIf);
			Assert.AreEqual(Matrix.RotationZ(Math.PIf), f.Matrix);
		}

		[Test]
		public void AppendRotation2()
		{
			var f = FastMatrix.FromFloat4x4(Matrix.RotationZ(Math.PIf / 2.0f));
			f.AppendRotation(Math.PIf);
			Assert.AreEqual(Matrix.RotationZ(Math.PIf * 1.5f), f.Matrix);
		}

		[Test]
		public void PrependRotation1()
		{
			var f = FastMatrix.Identity();
			f.PrependRotation(2.0f * Math.PIf);
			Assert.AreEqual(Matrix.RotationZ(2.0f * Math.PIf), f.Matrix);
		}

		[Test]
		public void PrependRotation2()
		{
			var s = Matrix.Scaling(2.0f);
			var r = Matrix.RotationZ(Math.PIf / 2.0f);
			var t = Matrix.Translation(float3(10, 20, 30));
			var m = Matrix.Mul(s, r, t);
			var f = FastMatrix.FromFloat4x4(m);
			f.PrependRotation(Math.PIf / 2.0f);
			Assert.AreEqual(Matrix.Mul(Matrix.RotationZ(Math.PIf / 2.0f), m), f.Matrix);
		}

		[Test]
		public void AppendScale1()
		{
			var f = FastMatrix.Identity();
			f.AppendScale(13.37f);
			Assert.AreEqual(Matrix.Scaling(13.37f), f.Matrix);
		}

		[Test]
		public void AppendScale2()
		{
			var s = Matrix.Scaling(3.0f);
			var r = Matrix.RotationZ(Math.PIf * (1 / 3));
			var t = Matrix.Translation(13, 37, 0);
			var m = Matrix.Mul(s, r, t);
			var f = FastMatrix.FromFloat4x4(m);
			f.AppendScale(10.0f);
			Assert.AreEqual(Matrix.Mul(m, Matrix.Scaling(10.0f)), f.Matrix);
		}

		[Test]
		public void PrependScale1()
		{
			var f = FastMatrix.Identity();
			f.PrependScale(13.37f);
			Assert.AreEqual(Matrix.Scaling(13.37f), f.Matrix);
		}

		[Test]
		public void PrependScale2()
		{
			var s = Matrix.Scaling(3.0f);
			var r = Matrix.RotationZ(Math.PIf * (2 / 3));
			var t = Matrix.Translation(13, 37, 0);
			var m = Matrix.Mul(s, r, t);
			var f = FastMatrix.FromFloat4x4(m);
			f.PrependScale(20.0f);
			Assert.AreEqual(Matrix.Mul(Matrix.Scaling(20.0f), m), f.Matrix);
		}

		[Test]
		public void AppendShear1()
		{
			var f = FastMatrix.Identity();
			f.AppendShear(Math.PIf, Math.PIf / 2.0f);
			Assert.AreEqual(Matrix.Shear(float2(Math.PIf, Math.PIf / 2.0f)), f.Matrix);
		}

		[Test]
		public void AppendShear2()
		{
			var s = Matrix.Scaling(3.0f);
			var r = Matrix.RotationZ(Math.PIf * (2 / 3));
			var t = Matrix.Translation(13, 37, 0);
			var m = Matrix.Mul(s, r, t);
			var f = FastMatrix.FromFloat4x4(m);
			f.AppendShear(Math.PIf * (1/3), Math.PIf * (2/3));
			Assert.AreEqual(Matrix.Mul(m, Matrix.Shear(float2(Math.PIf * (1/3), Math.PIf * (2/3)))), f.Matrix);
		}

		[Test]
		public void PrependShear1()
		{
			var f = FastMatrix.Identity();
			f.PrependShear(Math.PIf, Math.PIf);
			Assert.AreEqual(Matrix.Shear(float2(Math.PIf)), f.Matrix);
		}

		[Test]
		public void PrependShear2()
		{
			var s = Matrix.Scaling(3.0f);
			var r = Matrix.RotationZ(Math.PIf * (1 / 9));
			var t = Matrix.Translation(13, 37, 0);
			var m = Matrix.Mul(s, r, t);
			var f = FastMatrix.FromFloat4x4(m);
			f.PrependShear(Math.PIf * (1/6), Math.PIf * (1/3));
			Assert.AreEqual(Matrix.Mul(Matrix.Shear(float2(Math.PIf * (1/6), Math.PIf * (1/3))), m), f.Matrix);
		}

		[Test]
		public void Invert1()
		{
			var m = Matrix.Translation(float3(10, 20, 30));
			var f = FastMatrix.FromFloat4x4(m);
			f.Invert();

			float4x4 result;
			if (Matrix.TryInvert(m, out result))
			{
				Assert.AreEqual(result, f.Matrix);
				Assert.IsTrue(f.IsValid);
			}
			else
				Assert.IsFalse(f.IsValid);
		}

		[Test]
		public void Invert2()
		{
			var f = FastMatrix.FromFloat4x4(float4x4.Identity - float4x4.Identity);
			f.Invert();
			Assert.IsFalse(f.IsValid);
		}

		[Test]
		public void Invert3()
		{
			var s = Matrix.Scaling(3.0f);
			var r = Matrix.RotationZ(Math.PIf * (1 / 9));
			var t = Matrix.Translation(13, 37, 0);
			var m = Matrix.Mul(s, r, t);
			var f = FastMatrix.FromFloat4x4(m);
			f.Invert();

			float4x4 result;
			if (Matrix.TryInvert(m, out result))
			{
				Assert.AreEqual(result, f.Matrix);
				Assert.IsTrue(f.IsValid);
			}
			else
				Assert.IsFalse(f.IsValid);
		}

		[Test]
		public void AppendQuaternion1()
		{
			var f = FastMatrix.Identity();
			f.AppendRotationQuaternion(Quaternion.RotationZ(Math.PIf * (1/3)));
			Assert.AreEqual(Matrix.RotationZ(Math.PIf * (1/3)), f.Matrix);
		}

		[Test]
		public void Complex1()
		{
			var s = Matrix.Scaling(3.0f);
			var r = Matrix.RotationZ(Math.PIf * (1/9));
			var t = Matrix.Translation(10, 20, 30);
			var m = Matrix.Mul(s, r, t);
			var f = FastMatrix.Identity();
			f.AppendScale(3.0f);
			f.AppendRotation(Math.PIf * (1/9));
			f.AppendTranslation(float3(10, 20, 30));
			Assert.AreEqual(m, f.Matrix);
		}

		[Test]
		public void Complex2()
		{
			var s = Matrix.Scaling(3.0f);
			var r = Matrix.RotationZ(Math.PIf);
			var t = Matrix.Translation(13, 37, 13);
			var m = Matrix.Mul(s, r, t);
			var f1 = FastMatrix.FromFloat4x4(m);
			var f2 = FastMatrix.FromFloat4x4(Matrix.Invert(m));
			f1.AppendFastMatrix(f2);
			Assert.AreEqual(float4x4.Identity, f1.Matrix);
		}

		[Test]
		public void Complex3()
		{
			var f1 = FastMatrix.Identity();
			var f2 = FastMatrix.Identity();
			var f3 = FastMatrix.Identity();

			f1.AppendScale(3.0f);
			f2.AppendRotation(Math.PIf);
			f3.AppendTranslation(float3(10,20,30));

			f2.PrependFastMatrix(f1);
			f3.PrependFastMatrix(f2);

			var m = Matrix.Mul(
				Matrix.Scaling(3.0f),
				Matrix.RotationZ(Math.PIf),
				Matrix.Translation(10, 20, 30));

			Assert.AreEqual(m, f3.Matrix);
		}
	}
}
