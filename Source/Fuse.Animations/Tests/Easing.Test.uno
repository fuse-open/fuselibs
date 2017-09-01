using Uno;
using Uno.Compiler;
using Uno.Testing;
using Fuse.Animations;
using FuseTest;

namespace Fuse.Test
{
	public class EasingTest : TestBase
	{
		static float EvaluateAt(Easing e, float k)
		{
			return (float)e.Map(k);
		}

		static void TestEasingMode(Easing e, float2[] vals,
		                           [CallerFilePath] string filePath = "",
		                           [CallerLineNumber] int lineNumber = 0,
		                           [CallerMemberName] string memberName = "")
		{
			foreach (var val in vals)
				Assert.AreEqual(val.Y, EvaluateAt(e, val.X), Assert.ZeroTolerance, filePath, lineNumber, memberName);
		}

		[Test]
		public void QuadraticInOut()
		{
			TestEasingMode(Easing.QuadraticInOut, new float2[] {
				float2(0.0f,  0.0f),
				float2(0.25f, 0.125f),
				float2(0.5f,  0.5f),
				float2(0.75f, 0.875f),
				float2(1.0f,  1.0f)
				});
		}

		[Test]
		public void CubicInOut()
		{
			TestEasingMode(Easing.CubicInOut, new float2[] {
				float2(0.0f,  0.0f),
				float2(0.25f, 0.0625f),
				float2(0.5f,  0.5f),
				float2(0.75f, 0.9375f),
				float2(1.0f,  1.0f)
				});
		}

		[Test]
		public void QuarticInOut()
		{
			TestEasingMode(Easing.QuarticInOut, new float2[] {
				float2(0.0f,  0.0f),
				float2(0.25f, 0.03125f),
				float2(0.5f,  0.5f),
				float2(0.75f, 0.96875f),
				float2(1.0f,  1.0f)
				});
		}

		[Test]
		public void QuinticInOut()
		{
			TestEasingMode(Easing.QuinticInOut, new float2[] {
				float2(0.0f,   0.0f),
				float2(0.125f, 0.0004882813f),
				float2(0.25f,  0.015625f),
				float2(0.375f, 0.1186523f),
				float2(0.5f,   0.5f),
				float2(0.625f, 0.8813477f),
				float2(0.75f,  0.984375f),
				float2(0.875f, 0.9995117f),
				float2(1.0f,   1.0f)
				});
		}

		[Test]
		public void ExponentialInOut()
		{
			TestEasingMode(Easing.ExponentialInOut, new float2[] {
				float2(0.0f,   0.0f),
				float2(0.125f, 0.0027621f),
				float2(0.25f,  0.015625f),
				float2(0.375f, 0.0883883f),
				float2(0.5f,   0.5f),
				float2(0.625f, 0.9116117f),
				float2(0.75f,  0.984375f),
				float2(0.875f, 0.9972379f),
				float2(1.0f,   1.0f)
				});
		}

		[Test]
		public void CircularInOut()
		{
			TestEasingMode(Easing.CircularInOut, new float2[] {
				float2(0.0f,  0.0f),
				float2(0.25f, 0.0669873f),
				float2(0.5f,  0.5f),
				float2(0.75f, 0.9330127f),
				float2(1.0f,  1.0f)
				});
		}

		[Test]
		public void ElasticIn()
		{
			TestEasingMode(Easing.ElasticIn, new float2[] {
				float2(0.0f,    0.0f),
				float2(0.125f,  0.0008888f),
				float2(0.25f,   0.0039063f),
				float2(0.375f, -0.0121389f),
				float2(0.5f,    0.0f),
				float2(0.625f,  0.0686678f),
				float2(0.75f,  -0.125f),
				float2(0.875f, -0.1608986f),
				float2(1.0f,    1.0f)
				});
		}

		[Test]
		public void ElasticOut()
		{
			TestEasingMode(Easing.ElasticOut, new float2[] {
				float2(0.0f,    0.0f),
				float2(0.125f,  1.1608986f),
				float2(0.25f,   1.125f),
				float2(0.375f,  0.9313322f),
				float2(0.5f,    1.0f),
				float2(0.625f,  1.0121388f),
				float2(0.75f,   0.9960938f),
				float2(0.875f,  0.9991112f),
				float2(1.0f,    1.0f)
				});
		}

		[Test]
		public void ElasticInOut()
		{
			TestEasingMode(Easing.ElasticInOut, new float2[] {
				float2(0.0f,    0.0f),
				float2(0.125f,  0.0019531f),
				float2(0.25f,   0.0f),
				float2(0.375f, -0.0625f),
				float2(0.5f,    0.5f),
				float2(0.625f,  1.0625f),
				float2(0.75f,   1.0f),
				float2(0.875f,  0.9980469f),
				float2(1.0f,    1.0f)
				});
		}

		[Test]
		public void BackInOut()
		{
			TestEasingMode(Easing.BackInOut, new float2[] {
				float2(0.0f,    0.0f),
				float2(0.125f, -0.0530057f),
				float2(0.25f,  -0.0996818f),
				float2(0.375f,  0.0284829f),
				float2(0.5f,    0.5f),
				float2(0.625f,  0.9715171f),
				float2(0.75f,   1.0996819f),
				float2(0.875f,  1.0530057f),
				float2(1.0f,    1.0f)
				});
		}

		[Test]
		public void BounceOut()
		{
			TestEasingMode(Easing.BounceOut, new float2[] {
				float2(0.0f,    0.0f),
				float2(0.125f,  0.1181641f),
				float2(0.25f,   0.4726563f),
				float2(0.375f,  0.9697266f),
				float2(0.5f,    0.7656250f),
				float2(0.625f,  0.7978516f),
				float2(0.75f,   0.9726539f),
				float2(0.875f,  0.9619125f),
				float2(1.0f,    1.0f)
				});
		}
	}
}
